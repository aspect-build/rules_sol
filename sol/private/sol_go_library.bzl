"Implementation for sol_go_library rule"

load("@io_bazel_rules_go//go:def.bzl", "go_context")
load("//sol:providers.bzl", "SolBinaryInfo")

SOL_GO_LIBRARY_DEPS = [
    "@com_github_ethereum_go_ethereum//:go-ethereum",
    "@com_github_ethereum_go_ethereum//accounts/abi",
    "@com_github_ethereum_go_ethereum//accounts/abi/bind",
    "@com_github_ethereum_go_ethereum//common",
    "@com_github_ethereum_go_ethereum//core/types",
    "@com_github_ethereum_go_ethereum//event",
]

_ATTRS = {
    "binary": attr.label(
        doc = "The sol_binary target producing a combined.json for which `abigen` bindings are to be generated.",
        providers = [[SolBinaryInfo]],
        mandatory = True,
    ),
    "pkg": attr.string(
        doc = "Propagated to abigen --pkg",
        mandatory = True,
    ),
    "deps": attr.label_list(
        default = SOL_GO_LIBRARY_DEPS,
    ),
    "_abigen": attr.label(
        default = Label("@com_github_ethereum_go_ethereum//cmd/abigen"),
        allow_single_file = True,
        executable = True,
        cfg = "exec",
    ),
    "_go_context_data": attr.label(
        # https://github.com/bazelbuild/rules_go/blob/master/go/toolchains.rst#writing-new-go-rules
        default = "@io_bazel_rules_go//:go_context_data",
    ),
}

def _sol_go_library_impl(ctx):
    combined_json = ctx.attr.binary[SolBinaryInfo].combined_json

    args = ctx.actions.args()
    args.add("--lang", "go")
    args.add("--pkg", ctx.attr.pkg)
    args.add("--combined-json", combined_json.path)

    abigen_out = ctx.actions.declare_file("%s.sol.go" % ctx.attr.name)
    args.add("--out", abigen_out)

    ctx.actions.run(
        inputs = depset([combined_json]),
        outputs = [abigen_out],
        arguments = [args],
        executable = ctx.executable._abigen,
    )

    go = go_context(ctx)
    golib = go.new_library(
        go,
        srcs = [abigen_out],
        importable = True,
    )
    gosrc = go.library_to_source(
        go,
        attr = ctx.attr,
        library = golib,
        coverage_instrumented = ctx.coverage_instrumented(),
    )
    return [
        DefaultInfo(files = depset([abigen_out])),
        golib,
        gosrc,
        go.archive(go, source = gosrc),
    ]

sol_go_library = struct(
    implementation = _sol_go_library_impl,
    attrs = _ATTRS,
    toolchains = ["@io_bazel_rules_go//go:toolchain"],
)
