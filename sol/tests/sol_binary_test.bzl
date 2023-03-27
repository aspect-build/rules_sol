"""Unit tests for starlark helpers
See https://docs.bazel.build/versions/main/skylark/testing.html#for-testing-starlark-utilities
"""

load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts", "unittest")
load("@aspect_bazel_lib//lib:jq.bzl", "jq")
load("@aspect_bazel_lib//lib:write_source_files.bzl", "write_source_files")
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

def _extract_sol_binary_info_impl(ctx):
    info = ctx.attr.binary[SolBinaryInfo]
    return [DefaultInfo(files = depset([info.combined_json])), info]

_extract_sol_binary_info = rule(
    doc = "ensures that only the contents of SolBinaryInfo are accessible to tests",
    implementation = _extract_sol_binary_info_impl,
    attrs = {
        "binary": attr.label(
            mandatory = True,
            providers = [SolBinaryInfo],
        ),
    },
    provides = [SolBinaryInfo],
)

def _solc_version_test_impl(ctx):
    env = analysistest.begin(ctx)

    binary = analysistest.target_under_test(env)
    asserts.true(env, SolBinaryInfo in binary, "no SolBinaryInfo provider")

    info = binary[SolBinaryInfo]
    asserts.equals(env, ctx.attr.expected, info.solc_version, "SolBinaryInfo.solc_version")
    asserts.true(env, info.solc_bin.find(info.solc_version) != -1, "SolBinaryInfo.solc_bin includes SolBinaryInfo.solc_version")

    return analysistest.end(env)

_solc_version_test = analysistest.make(
    _solc_version_test_impl,
    attrs = {
        "expected": attr.string(
            mandatory = True,
        ),
    },
)

def solc_version_test(name = "", target_under_test = "", **kwargs):
    """Tests that a sol_binary correctly exposes the solc version.

    Args:
      name: name of the test target
      target_under_test: propagated to the skylib analysistest
      **kwargs: propagated to the skylib analysistest
    """
    INFO_ONLY = "_%s_sol_binary_info" % name
    _extract_sol_binary_info(
        name = INFO_ONLY,
        binary = target_under_test,
    )

    JQ = "_%s_jq" % name
    jq(
        name = JQ,
        srcs = [INFO_ONLY],
        filter_file = "combined_json.version.jq",
        args = ["--raw-output"],
    )
    write_source_files(
        name = "%s_combined_json_version" % name.removesuffix("_test"),
        files = {"%s.version.json" % name: JQ},
    )

    _solc_version_test(
        name = name,
        target_under_test = target_under_test,
        **kwargs
    )
