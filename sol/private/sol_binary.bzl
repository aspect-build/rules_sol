"""Implementation details for sol_binary.

TODO:
- use `--optimize` if compilation_mode=opt
- make it silent on success
"""

load("@bazel_skylib//lib:paths.bzl", "paths")
load("@aspect_rules_js//js:providers.bzl", "JsInfo")
load("@aspect_rules_js//js:libs.bzl", "js_lib_helpers")
load("//sol:providers.bzl", "SolRemappingsInfo", "SolSourcesInfo", "sol_remappings_info")

_OUTPUT_COMPONENTS = ["abi", "asm", "ast", "bin", "bin-runtime", "devdoc", "function-debug", "function-debug-runtime", "generated-sources", "generated-sources-runtime", "hashes", "metadata", "opcodes", "srcmap", "srcmap-runtime", "storage-layout", "userdoc"]
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
        providers = [[SolRemappingsInfo, SolSourcesInfo], [JsInfo]],
    ),
    "bin": attr.bool(
        doc = "Whether to emit binary of the contracts in hex.",
    ),
    "ast_compact_json": attr.bool(
        doc = "Whether to emit AST of all source files in a compact JSON format.",
    ),
    "combined_json": attr.string_list(
        doc = """Output a single json document containing the specified information.""",
        # Thanks bazel... https://github.com/bazelbuild/bazel/issues/6638
        # allowed values can't be specified here
        default = ["abi", "bin", "hashes"],
    ),
    "solc": attr.string(),
    "_allowlist_function_transition": attr.label(
        default = "@bazel_tools//tools/allowlists/function_transition_allowlist"
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
        if len(ctx.attr.combined_json):
            result.append(ctx.actions.declare_file("combined.json"))
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

    remappings_info = sol_remappings_info(ctx)
    for (prefix, target) in remappings_info.remappings.items():
        args.add_joined([prefix, target], join_with = "=")

    if len(root_packages):
        args.add("--include-path")
        args.add_joined(
            root_packages,
            format_each = ctx.bin_dir.path + "/%s/node_modules",
            join_with = ",",
            uniquify = True,
        )

    if ctx.attr.bin:
        args.add("--bin")
    if ctx.attr.ast_compact_json:
        args.add("--ast-compact-json")
    for v in ctx.attr.combined_json:
        if v not in _OUTPUT_COMPONENTS:
            fail("Illegal output component {}, must be one of {}".format(v, _OUTPUT_COMPONENTS))
    if len(ctx.attr.combined_json):
        args.add("--combined-json")
        args.add_joined(ctx.attr.combined_json, join_with = ",")

    outputs = _calculate_outs(ctx)
    if not len(outputs):
        fail("No outputs were requested. This is illegal under Bazel, as actions are only run to produce output files.")

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
        progress_message = "solc compile " + outputs[0].short_path,
    )

    return [
        DefaultInfo(files = depset(outputs)),
        remappings_info,
    ]

def _sol_binary_impl(ctx):
    return _run_solc(ctx)


def _impl(settings, attr):
    if attr.solc:
        return {
            "//sol/private:solc_version": attr.solc
        }
    return {}

solc_version_transition = transition(
    implementation = _impl,
    inputs =  [],
    outputs = ["//sol/private:solc_version"],
)

sol_binary = struct(
    implementation = _sol_binary_impl,
    attrs = _ATTRS,
    toolchains = ["@aspect_rules_sol//sol:toolchain_type"],
    cfg = solc_version_transition
)
