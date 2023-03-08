"Shared functionality used by one or more rule"

load("//sol:providers.bzl", "SolRemappingsInfo")

def transitive_remappings(ctx, extra_remappings = {}):
    """Combine remappings from ctx.deps.

    Fails if duplicate remapping prefixes are found with different targets.

    Args:
        ctx: Context object from which deps are sourced.
        extra_remappings: Additional remappings to be added to those found in ctx.deps.

    Returns:
    The union of extra_remappings and all remappings in ctx.deps that provide SolRemappingsInfo.
    """

    remappings = {k: v for (k, v) in extra_remappings.items()}
    for dep in ctx.attr.deps:
        if SolRemappingsInfo in dep:
            for prefix, target in dep[SolRemappingsInfo].remappings.items():
                if prefix in remappings:
                    if remappings[prefix] == target:
                        continue
                    fail("Duplicate remappings prefix %s" % prefix)
                remappings[prefix] = target

    return remappings
