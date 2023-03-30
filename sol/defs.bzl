"""# Bazel rules for Solidity

See <https://docs.soliditylang.org>
"""

load("//sol/private:sol_binary.bzl", lib = "sol_binary")
load("//sol/private:sol_go_library.bzl", _SOL_GO_LIBRARY_DEPS = "SOL_GO_LIBRARY_DEPS", go = "sol_go_library")
load("//sol/private:sol_remappings.bzl", remap = "sol_remappings")
load("//sol/private:sol_sources.bzl", src = "sol_sources")
load(":providers.bzl", "SolBinaryInfo", "SolRemappingsInfo", "SolSourcesInfo")

sol_binary = rule(
    implementation = lib.implementation,
    attrs = lib.attrs,
    cfg = lib.cfg,
    doc = """sol_binary compiles Solidity source files with solc""",
    toolchains = lib.toolchains,
    provides = [SolBinaryInfo, SolRemappingsInfo],
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

sol_go_library = rule(
    implementation = go.implementation,
    attrs = go.attrs,
    doc = """Generate Solidity Go bindings using abigen. This target is embeddable in a go_library / go_binary.

Note that Gazelle is unaware of sol_go_library(). The target must therefore be
embedded with a #keep to avoid it being removed. If the embed is the only embed
and no src is provided, then the embedding target's importpath must also be
tagged with #keep.

Example usage:
```
    sol_binary(
        name = "nft_sol",
        srcs = [
            "MyNFT.sol",
            "MyFancyStakingMechanism.sol",
        ],
        pkg = "nft",
        deps = ["@openzeppelin-contracts_4-8-1"], # see sol_git_repository
    )
    sol_go_library(
        name = "nft_sol_go",
        binary = ":nft_sol",
        pkg = "nft",
    )
    go_library(
        name = "nft",
        embed = [
            ":nft_sol_go", #keep
        ],
        importpath = "github.com/org/repo/path/to/nft", #keep
    )
    go_test(
        name = "nft_test",
        embed = [
            ":nft_sol", #keep
            # and/or embed [":nft"] with #keep as necessary
        ],
    )
```""",
    provides = ["GoArchive", "GoLibrary", "GoSource"],
    toolchains = go.toolchains,
)

SOL_GO_LIBRARY_DEPS = _SOL_GO_LIBRARY_DEPS
