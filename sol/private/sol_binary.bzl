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
    # Effectively disable this security feature - Bazel's sandbox ensures reproducibility
    # Anyhow, as very few compilers do such a thing, the solc layer isn't the right place to solve.
    args.add_all(["--allow-paths", "/"])

    ctx.actions.run(
        executable = solinfo.target_tool_path,
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
