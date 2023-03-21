"Providers for rule interop"

load(
    "//sol/private:sol_remappings_info.bzl",
    _SolRemappingsInfo = "SolRemappingsInfo",
    _sol_remappings_info = "sol_remappings_info",
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
