<!-- Generated with Stardoc: http://skydoc.bazel.build -->

# Bazel rules for Solidity

See <https://docs.soliditylang.org>


<a id="sol_binary"></a>

## sol_binary

<pre>
sol_binary(<a href="#sol_binary-name">name</a>, <a href="#sol_binary-args">args</a>, <a href="#sol_binary-ast_compact_json">ast_compact_json</a>, <a href="#sol_binary-bin">bin</a>, <a href="#sol_binary-combined_json">combined_json</a>, <a href="#sol_binary-deps">deps</a>, <a href="#sol_binary-optimize">optimize</a>, <a href="#sol_binary-optimize_runs">optimize_runs</a>,
           <a href="#sol_binary-solc_version">solc_version</a>, <a href="#sol_binary-srcs">srcs</a>)
</pre>

sol_binary compiles Solidity source files with solc

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="sol_binary-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="sol_binary-args"></a>args |  Additional command-line arguments to solc. Run solc --help for a listing.   | List of strings | optional | [] |
| <a id="sol_binary-ast_compact_json"></a>ast_compact_json |  Whether to emit AST of all source files in a compact JSON format.   | Boolean | optional | False |
| <a id="sol_binary-bin"></a>bin |  Whether to emit binary of the contracts in hex.   | Boolean | optional | False |
| <a id="sol_binary-combined_json"></a>combined_json |  Output a single json document containing the specified information.   | List of strings | optional | ["abi", "bin", "hashes"] |
| <a id="sol_binary-deps"></a>deps |  Solidity libraries, either first-party sol_sources, or third-party distributed as packages on npm   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional | [] |
| <a id="sol_binary-optimize"></a>optimize |  Set the solc --optimize flag.<br><br>        See https://docs.soliditylang.org/en/latest/using-the-compiler.html#optimizer-options   | Boolean | optional | False |
| <a id="sol_binary-optimize_runs"></a>optimize_runs |  Set the solc --optimize-runs flag.<br><br>        See https://docs.soliditylang.org/en/latest/using-the-compiler.html#optimizer-options   | Integer | optional | 200 |
| <a id="sol_binary-solc_version"></a>solc_version |  -   | String | optional | "" |
| <a id="sol_binary-srcs"></a>srcs |  Solidity source files   | <a href="https://bazel.build/concepts/labels">List of labels</a> | required |  |


<a id="sol_remappings"></a>

## sol_remappings

<pre>
sol_remappings(<a href="#sol_remappings-name">name</a>, <a href="#sol_remappings-deps">deps</a>, <a href="#sol_remappings-remappings">remappings</a>)
</pre>

sol_remappings combines remappings from multiple targets, and generates a Forge-compatible remappings.txt file.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="sol_remappings-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="sol_remappings-deps"></a>deps |  sol_binary, sol_sources, or other sol_remappings targets from which remappings are combined.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | required |  |
| <a id="sol_remappings-remappings"></a>remappings |  Additional import remappings.   | <a href="https://bazel.build/rules/lib/dict">Dictionary: String -> String</a> | optional | {} |


<a id="sol_sources"></a>

## sol_sources

<pre>
sol_sources(<a href="#sol_sources-name">name</a>, <a href="#sol_sources-deps">deps</a>, <a href="#sol_sources-remappings">remappings</a>, <a href="#sol_sources-srcs">srcs</a>)
</pre>

Collect .sol source files to be imported as library code.
    Performs no actions, so semantically equivalent to filegroup().
    

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="sol_sources-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="sol_sources-deps"></a>deps |  Each dependency should either be more .sol sources, or npm packages for 3p dependencies   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional | [] |
| <a id="sol_sources-remappings"></a>remappings |  Contribute to import mappings.<br><br>        See https://docs.soliditylang.org/en/latest/path-resolution.html?highlight=remappings#import-remapping   | <a href="https://bazel.build/rules/lib/dict">Dictionary: String -> String</a> | optional | {} |
| <a id="sol_sources-srcs"></a>srcs |  Solidity source files   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional | [] |


