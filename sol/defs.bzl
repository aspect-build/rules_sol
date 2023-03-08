"""# Bazel rules for Solidity

See <https://docs.soliditylang.org>
"""

load("//sol/private:sol_binary.bzl", lib = "sol_binary")
load("//sol/private:sol_remappings.bzl", remap = "sol_remappings")
load("//sol/private:sol_sources.bzl", src = "sol_sources")
load(":providers.bzl", "SolRemappingsInfo", "SolSourcesInfo")

sol_binary = rule(
    implementation = lib.implementation,
    attrs = lib.attrs,
    doc = """sol_binary compiles Solidity source files with solc""",
    toolchains = lib.toolchains,
    provides = [SolRemappingsInfo],
)

sol_remappings = rule(
    implementation = remap.implementation,
    attrs = remap.attrs,
    doc = """sol_remappings combines remappings from multiple targets, and generates a Forge-compatible remappings.txt file.""",
    provides = [SolRemappingsInfo],
)

sol_sources = rule(
    implementation = src.implementation,
    attrs = src.attrs,
    doc = """Collect .sol source files to be imported as library code.
    Performs no actions, so semantically equivalent to filegroup().
    """,
    provides = [SolRemappingsInfo, SolSourcesInfo],
)
