"""# Bazel rules for Solidity

See <https://docs.soliditylang.org>
"""

load("//sol/private:sol_binary.bzl", lib = "sol_binary")

sol_binary = rule(
    implementation = lib.implementation,
    attrs = lib.attrs,
    doc = """sol_binary compiles Solidity source files with solc""",
    toolchains = lib.toolchains,
)
