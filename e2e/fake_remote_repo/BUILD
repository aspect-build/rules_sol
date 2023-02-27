load("@aspect_rules_sol//sol:defs.bzl", "sol_sources")

REMAP_TARGET = "./external/fake_remote_repo/"

sol_sources(
    name = "echo",
    srcs = ["Echo.sol"],
    remappings = {
        "remapped-fake-remote-repo/": REMAP_TARGET,
        # Although this alternate isn't used for imports, it's included to
        # demonstrate complete generation of remappings.txt by the sol_binary()
        # that depends on this sol_sources().
        "alternate-remapped-fake-remote-repo/": REMAP_TARGET,
    },
    visibility = ["//visibility:public"],
)
