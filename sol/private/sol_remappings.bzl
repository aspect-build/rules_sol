"""Implementation for sol_remappings."""

load("//sol:providers.bzl", "SolRemappingsInfo")
load("//sol/private:common.bzl", "transitive_remappings")

_ATTRS = {
    "deps": attr.label_list(
        doc = "sol_binary, sol_sources, or other sol_remappings targets from which remappings are combined.",
        providers = [[SolRemappingsInfo]],
        mandatory = True,
    ),
    "remappings": attr.string_dict(
        doc = "Additional import remappings.",
        default = {},
    ),
}

def _sol_remappings_impl(ctx):
    remappings = transitive_remappings(ctx, ctx.attr.remappings)

    output = ctx.actions.declare_file("remappings.txt")
    ctx.actions.write(
        output = output,
        content = "\n".join(["%s=%s" % x for x in remappings.items()]),
    )

    return [
        DefaultInfo(files = depset([output])),
        SolRemappingsInfo(remappings = remappings),
    ]

sol_remappings = struct(
    implementation = _sol_remappings_impl,
    attrs = _ATTRS,
)
