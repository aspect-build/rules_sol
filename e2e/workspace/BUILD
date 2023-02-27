load("@bazel_skylib//rules:select_file.bzl", "select_file")
load("@aspect_rules_sol//sol:defs.bzl", "sol_binary")
load("@aspect_bazel_lib//lib:write_source_files.bzl", "write_source_files")

sol_binary(
    name = "solc",
    srcs = ["HelloWorld.sol"],
    ast_compact_json = True,
    deps = ["@fake_remote_repo//:echo"],
)

select_file(
    name = "pick_ast",
    srcs = "solc",
    subpath = "HelloWorld.sol_json.ast",
)

select_file(
    name = "pick_remappings",
    srcs = "solc",
    subpath = "remappings.txt",
)

write_source_files(
    name = "write_golden",
    files = {
        "HelloWorld.json": "pick_ast",
        "remappings.txt": "pick_remappings",
    },
)
