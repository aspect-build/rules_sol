// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

contract Echo {
    function echo(string memory payload) external pure returns (string memory) {
        return string(abi.encodePacked("Solidity: ", payload));
    }
}
