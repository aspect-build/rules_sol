"Providers for rule interop"

SolSourcesInfo = provider(
    doc = "Stores a tree of source file dependencies",
    fields = {
        "direct_sources": "list of sources provided to this node",
        "transitive_sources": "depset of transitive dependency sources",
    },
)

SolRemappingsInfo = provider(
    doc = """Stores a dictionary of solc remappings.
    
    Allows for piping of remappings through a dependency tree of targets. Rules
    that accept a "remappings" attribute and/or dependencies that provide
    SolRemappingsInfo SHOULD propagate their union via a SolRemappingsInfo.
    """,
    fields = {
        "remappings": "dictionary of import remappings to propagate to solc",
    },
)
