"""Unit tests for starlark helpers
See https://docs.bazel.build/versions/main/skylark/testing.html#for-testing-starlark-utilities
"""

load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts", "unittest")
load("//sol:providers.bzl", "SolBinaryInfo")
load("//sol/private:versions.bzl", "TOOL_VERSIONS")

def _smoke_test_impl(ctx):
    env = unittest.begin(ctx)
    asserts.equals(env, "macosx-amd64", TOOL_VERSIONS.keys()[0])
    return unittest.end(env)

# The unittest library requires that we export the test cases as named test rules,
# but their names are arbitrary and don't appear anywhere.
_t0_test = unittest.make(_smoke_test_impl)

def sol_binary_test_suite(name):
    unittest.suite(name, _t0_test)

def _solc_version_test_impl(ctx):
    env = analysistest.begin(ctx)

    binary = analysistest.target_under_test(env)
    asserts.true(env, SolBinaryInfo in binary, "no SolBinaryInfo provider")

    info = binary[SolBinaryInfo]
    asserts.equals(env, ctx.attr.expected, info.solc_version, "SolBinaryInfo.solc_version")
    asserts.true(env, info.solc_binary.find(info.solc_version) != -1, "SolBinaryInfo.solc_binary includes SolBinaryInfo.solc_version")

    return analysistest.end(env)

solc_version_test = analysistest.make(
    _solc_version_test_impl,
    attrs = {
        "expected": attr.string(
            mandatory = True,
        ),
    },
)
