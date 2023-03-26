"Providers for rule interop"

load(
    "//sol/private:sol_remappings_info.bzl",
    _SolRemappingsInfo = "SolRemappingsInfo",
    _sol_remappings_info = "sol_remappings_info",
)

SolBinaryInfo = provider(
    doc = "Stores outputs of a sol_binary",
    fields = {
        "solc_version": "version of solc used",
        "solc_binary": "full basename of solc binary used, including platform and commit ID",
        "combined_json": "combined.json file produced by solc",
    },
)

SolSourcesInfo = provider(
    doc = "Stores a tree of source file dependencies",
    fields = {
        "direct_sources": "list of sources provided to this node",
        "transitive_sources": "depset of transitive dependency sources",
    },
)

SolRemappingsInfo = _SolRemappingsInfo
sol_remappings_info = _sol_remappings_info
