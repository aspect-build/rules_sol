// From https://blog.soliditylang.org/2023/02/22/user-defined-operators/
// This needs the latest solidity compiler as of March 2023
pragma solidity ^0.8.19;

type Int is int;
using {add as +} for Int global;

function add(Int a, Int b) pure returns (Int) {
    return Int.wrap(Int.unwrap(a) + Int.unwrap(b));
}

function test(Int a, Int b) pure returns (Int) {
    return a + b; // Equivalent to add(a, b)
}
