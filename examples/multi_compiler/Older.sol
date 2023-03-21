pragma solidity >=0.7.0 <0.8.0;
// Underflow is illegal starting in Solidity 0.8.0
// https://blog.soliditylang.org/2020/12/16/solidity-v0.8.0-release-announcement/
contract C {
    function f() public pure {
        uint x = 0;
        x--;
    }
}