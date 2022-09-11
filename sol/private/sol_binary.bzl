"""Implementation details for sol_binary.

TODO:
- use `--optimize` if compilation_mode=opt
"""
load("@bazel_skylib//lib:paths.bzl", "paths")

_ATTRS = {
    "srcs": attr.label_list(
        doc = "Solidity source files",
        mandatory = True,
        allow_files = [".sol"],
    ),
    "args": attr.string_list(
        doc = "Additional command-line arguments to solc. Run solc --help for a listing.",
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
    if ctx.attr.bin:
        result.extend([
            ctx.actions.declare_file(paths.replace_extension(s.short_path, ".bin"))
            for s in ctx.files.srcs
        ])
    if ctx.attr.ast_compact_json:
        result.extend([
            ctx.actions.declare_file(s.short_path + "_json.ast")
            for s in ctx.files.srcs
        ])
    return result

def _run_solc(ctx):
    "Generate action(s) to run the compiler"
    solinfo = ctx.toolchains["@aspect_rules_sol//sol:toolchain_type"].solinfo
    args = ctx.actions.args()

    # User-provided arguments first, so we can override them
    args.add_all(ctx.attr.args)
    
    args.add_all([s.path for s in ctx.files.srcs])
    
    args.add("--output-dir")
    args.add_joined([ctx.bin_dir.path, ctx.label.package], join_with = "/")

    if ctx.attr.bin:
        args.add("--bin")
    if ctx.attr.ast_compact_json:
        args.add("--ast-compact-json")
    
    outputs = _calculate_outs(ctx)
    ctx.actions.run(
        executable = solinfo.target_tool_path,
        arguments = [args],
        inputs = ctx.files.srcs,
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
