"Shared functionality used by one or more rule"

load("//sol:providers.bzl", "SolRemappingsInfo")

def transitive_remappings(ctx, add_remappings = {}):
    """Returns the union of extra_remappings and all remappings in ctx.deps that provide SolRemappingsInfo.

    Fails if duplicate remapping prefixes are found with different targets.

    Args:
        ctx: TODO
        add_remappings: TODO

    Returns:
    TODO
    """

    remappings = {k: v for (k, v) in add_remappings.items()}
    for dep in ctx.attr.deps:
        if SolRemappingsInfo in dep:
            for prefix, target in dep[SolRemappingsInfo].remappings.items():
                if prefix in remappings:
                    if remappings[prefix] == target:
                        continue
                    fail("Duplicate remappings prefix %s" % prefix)
                remappings[prefix] = target

    return remappings
