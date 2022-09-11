# Declare the local Bazel workspace.
workspace(
    # If your ruleset is "official"
    # (i.e. is in the bazelbuild GitHub org)
    # then this should just be named "rules_sol"
    # see https://docs.bazel.build/versions/main/skylark/deploying.html#workspace
    name = "aspect_rules_sol",
)

load(":internal_deps.bzl", "rules_sol_internal_deps")

# Fetch deps needed only locally for development
rules_sol_internal_deps()

load("//sol:repositories.bzl", "LATEST_VERSION", "rules_sol_dependencies", "sol_register_toolchains")

# Fetch dependencies which users need as well
rules_sol_dependencies()

# Demonstrate that we can have multiple versions of solc available to Bazel rules
[
    sol_register_toolchains(
        name = "solc_" + v.replace(".", "_"),
        sol_version = v,
    )
    for v in [
        LATEST_VERSION,
        "0.8.9",
    ]
]

# For running our own unit tests
load("@bazel_skylib//:workspace.bzl", "bazel_skylib_workspace")

bazel_skylib_workspace()

############################################
# Gazelle, for generating bzl_library targets
load("@io_bazel_rules_go//go:deps.bzl", "go_register_toolchains", "go_rules_dependencies")
load("@bazel_gazelle//:deps.bzl", "gazelle_dependencies")

go_rules_dependencies()

go_register_toolchains(version = "1.17.2")

gazelle_dependencies()
