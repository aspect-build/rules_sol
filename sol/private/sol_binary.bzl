"""Implementation details for sol_binary.

TODO:
- use `--optimize` if compilation_mode=opt
"""
load("@bazel_skylib//lib:paths.bzl", "paths")
load("@aspect_rules_js//js:providers.bzl", "JsInfo")
load("@aspect_rules_js//js:libs.bzl", "js_lib_helpers")
load("//sol:providers.bzl", "SolSourcesInfo")

_ATTRS = {
    "srcs": attr.label_list(
        doc = "Solidity source files",
        mandatory = True,
        allow_files = [".sol"],
    ),
    "args": attr.string_list(
        doc = "Additional command-line arguments to solc. Run solc --help for a listing.",
    ),
    "deps": attr.label_list(
        doc = "Solidity libraries, either first-party sol_sources, or third-party distributed as packages on npm",
        providers = [[SolSourcesInfo], [JsInfo]],
    ),
    "bin": attr.bool(
        doc = "Whether to emit binary of the contracts in hex.",
        default = True,
    ),
    "ast_compact_json": attr.bool(
        doc = "Whether to emit AST of all source files in a compact JSON format.",
    )
}

def _calculate_outs(ctx):
    "Predict what files the solc compiler will emit"
    result = []
    for src in ctx.files.srcs:
        relative_src = paths.relativize(src.short_path, ctx.label.package)
        if ctx.attr.bin:
            result.append(ctx.actions.declare_file(paths.replace_extension(relative_src, ".bin")))
        if ctx.attr.ast_compact_json:
            result.append(ctx.actions.declare_file(relative_src + "_json.ast"))
    return result

def _gather_transitive_sources(attr):
    result = []
    for dep in attr:
        if SolSourcesInfo in dep:
            result.append(dep[SolSourcesInfo].transitive_sources)
    return result

def _run_solc(ctx):
    "Generate action(s) to run the compiler"
    solinfo = ctx.toolchains["@aspect_rules_sol//sol:toolchain_type"].solinfo
    args = ctx.actions.args()

    # User-provided arguments first, so we can override them
    args.add_all(ctx.attr.args)
    
    args.add_all([s.path for s in ctx.files.srcs])
    
    # TODO: is this the right value? maybe it ought to be the package directory?
    args.add_all(["--base-path", "."])

    args.add("--output-dir")
    args.add_joined([ctx.bin_dir.path, ctx.label.package], join_with = "/")

    root_packages = []
    for dep in ctx.attr.deps:
        if JsInfo in dep:
            for pkg in dep[JsInfo].transitive_npm_linked_packages.to_list():
                # Where the node_modules were installed
                root_packages.append(pkg.store_info.root_package)

    if len(root_packages):
        args.add("--include-path")
        args.add_joined(root_packages,
            format_each = ctx.bin_dir.path + "/%s/node_modules",
            join_with = ",",
            uniquify = True,
        )

    if ctx.attr.bin:
        args.add("--bin")
    if ctx.attr.ast_compact_json:
        args.add("--ast-compact-json")

    outputs = _calculate_outs(ctx)
    npm_deps = js_lib_helpers.gather_files_from_js_providers(ctx.attr.deps, include_transitive_sources = True, include_declarations = False, include_npm_linked_packages = True)

    # solc will follow symlinks out of the sandbox, then insist that the execroot path is allowed.
    #
    # This seems to be an understood limitation, for example in https://github.com/ethereum/solidity/issues/11410:
    # > NOTE: --allowed-directories becomes almost redundant after these changes. There are now only two cases where it's needed:
    # > When a file is a symlink that leads to a file outside of base path or include directories.
    # > The directory containing the symlink target must be in --allowed-directories for this to be allowed.
    #
    # In theory, we could just pass the flag by adding it to the args here:
    # args.add_all(["--allow-paths", "/shared/cache/bazel/user_base/4852a32ae4e0a9af81db7a9d3d23d028/execroot"])
    # However, there's not a way in Bazel to construct such a path out of the sandbox.
    # An alternative would be to skip sandboxing, like with
    #  args.add("--overwrite")
    #  execution_requirements["no-sandbox"] = "1"
    # but then, we run into a different problem where solc sees the non-sandboxed copy of the dependencies, and fails:
    # Error: Source "@openzeppelin/contracts/utils/structs/BitMaps.sol" not found: Ambiguous import.
    # Multiple matching files found inside base path and/or include paths: 
    # "/shared/cache/bazel/user_base/2a38f4143004a5b13cc7ebd21a4945b4/execroot/__main__/bazel-out/k8-fastbuild/bin/node_modules/.aspect_rules_js/@openzeppelin+contracts@4.7.0/node_modules/@openzeppelin/contracts/utils/structs/BitMaps.sol",
    # "/shared/cache/bazel/user_base/2a38f4143004a5b13cc7ebd21a4945b4/execroot/__main__/bazel-out/k8-fastbuild/bin/node_modules/.aspect_rules_js/@openzeppelin+contracts@4.7.0/node_modules/@openzeppelin/contracts/utils/structs/BitMaps.sol".
    #
    # So, our solution is to wrap solc with a small program that calculates a path to the non-sandbox execroot and add the --allow-paths flag.
    shim = ctx.actions.declare_file("run_solc.sh")
    ctx.actions.write(
        output = shim,
        content = """#!/usr/bin/env bash
extra_arg=""
search="$(pwd)"
while true; do
    [[ "$search" == "/" ]] && break
    if [[ $(basename "$search") == "sandbox" ]]; then
        # Explicitly allow solc to read files in the execroot outside the Bazel sandbox
        extra_arg="--allow-paths $(pwd),$(dirname $search),/home/alexeagle/Projects/rules_sol/examples/npm_deps/"
    fi
    search="$(dirname "$search")"
done
exec {solc} $@ $extra_arg""".format(
            solc = solinfo.target_tool_path
        ),
        is_executable = True,
    )

    ctx.actions.run(
        executable = shim,
        arguments = [args],
        inputs = depset(ctx.files.srcs, transitive = _gather_transitive_sources(ctx.attr.deps) + [npm_deps]),
        outputs = outputs,
        tools = solinfo.tool_files,
        mnemonic = "Solc",
        progress_message = "solc compile " + outputs[0].path,
    )

    return depset(outputs)

def _sol_binary_impl(ctx):
    return [
        DefaultInfo(files = _run_solc(ctx))
    ]

sol_binary = struct(
    implementation = _sol_binary_impl,
    attrs = _ATTRS,
    toolchains = ["@aspect_rules_sol//sol:toolchain_type"],
)
