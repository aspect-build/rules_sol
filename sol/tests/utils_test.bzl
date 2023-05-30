"""Unit tests for utils.bzl"""

load("//sol/private:utils.bzl", "semver_cmp")
load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")

def _semver_cmp_test_impl(ctx):
    env = unittest.begin(ctx)

    # All non-equal tests will be automatically reversed and have their expected
    # result reversed.
    tests = [
        ["0.0.0", "0.0.0", 0],
        ["0.0.0", "0.0.1", -1],
        ["0.0.1", "0.1.0", -1],  # demonstrate early bail-out
        ["0.1.1", "1.0.0", -1],  # ditto
        ["0.8.17", "0.8.18", -1],  # 0.8.18 is the solc minimum version for --no-cbor-metadata
        ["0.8.18", "0.8.19", -1],
        ["0.8.18", "0.9.0", -1],
        ["0.8.18", "0.7.18", 1],
    ]

    n = len(tests)  # appending to the tests list changes len(tests) in the loop
    for i in range(n):
        test = tests[i]
        if test[2] == 0:
            continue
        tests.append([test[1], test[0], -test[2]])

    for test in tests:
        msg = "semver_cmp(%s, %s)" % (test[0], test[1])
        asserts.equals(env, semver_cmp(test[0], test[1]), test[2], msg)

    return unittest.end(env)

semver_cmp_test = unittest.make(_semver_cmp_test_impl)

def utils_test_suite():
    unittest.suite("semver_cmp_tests", semver_cmp_test)
