"""Shared functionality used by one or more rules."""

SolRemappingsInfo = provider(
    doc = """Stores a dictionary of solc remappings.
    
    Allows for piping of remappings through a dependency tree of targets. Rules
    that accept a "remappings" attribute and/or dependencies that provide
    SolRemappingsInfo SHOULD propagate their union via a SolRemappingsInfo.
    """,
    fields = {
        "remappings": "dictionary of import remappings to propagate to solc",
    },
)

def sol_remappings_info(ctx, extra_remappings = {}):
    """Construct a SolRemappingsInfo.

    Fails if duplicate remapping prefixes are found with different targets.

    Args:
        ctx: Context object from the implementation constructing a SolRemappingsInfo. All deps will be checked for
        SolRemappingsInfo providers to transitively propagate.
        extra_remappings: Additional remappings to be added to those found in ctx.srcs and ctx.deps.
    """
    return SolRemappingsInfo(
        remappings = _transitive_remappings(ctx, extra_remappings),
    )

def _transitive_remappings(ctx, extra_remappings = {}):
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
