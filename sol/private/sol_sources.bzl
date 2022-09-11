"Implementation for sol_sources rule"
load("@aspect_rules_js//js:providers.bzl", "JsInfo", "js_info")
load("//sol:providers.bzl", "SolSourcesInfo")
load("@aspect_rules_js//js:libs.bzl", "js_lib_helpers")

_ATTRS = {
    "srcs": attr.label_list(
        allow_files = [".sol"],
        doc = "Solidity source files",
    ),
    "deps": attr.label_list(
        doc = "Each dependency should either be more .sol sources, or npm packages for 3p dependencies",
        providers = [[SolSourcesInfo], [JsInfo]],
    ),
}

def _sol_sources_impl(ctx):
    npm_linked_packages = js_lib_helpers.gather_npm_linked_packages(
        srcs = ctx.attr.srcs,
        deps = ctx.attr.deps,
    )

    return [
        DefaultInfo(
            files = depset(ctx.files.srcs),
        ),
        SolSourcesInfo(
            direct_sources = ctx.files.srcs,
            transitive_sources = depset(
                ctx.files.srcs,
                transitive = [
                    d[SolSourcesInfo].transitive_sources
                    for d in ctx.attr.deps
                    if SolSourcesInfo in d
                ]
            ),
        ),
        js_info(
            npm_linked_packages = npm_linked_packages.direct,
            npm_linked_package_files = npm_linked_packages.direct_files,
            transitive_npm_linked_package_files = npm_linked_packages.transitive_files,
            transitive_npm_linked_packages = npm_linked_packages.transitive,
        ),
    ]

sol_sources = struct(
    implementation = _sol_sources_impl,
    attrs = _ATTRS,
)
