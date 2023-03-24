//SPDX-License-Identifier: UNLICENSED
// note, ==0.7.6 fails with
// requires different compiler version (current compiler is 0.7.6+commit.7338295f.Linux.g++)
pragma solidity >=0.7.6 <0.7.7;

// Underflow is illegal starting in Solidity 0.8.0
// https://blog.soliditylang.org/2020/12/16/solidity-v0.8.0-release-announcement/
// Therefore this code would fail to compile unless the `solc_version` attribute is honored.
contract C {
    function f() public pure {
        uint x = 0;
        x--;
    }
}