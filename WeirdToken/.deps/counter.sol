// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8;

contract Counter {
    uint256 public count;

    function inc() external {
        count++;
    }

    function dec() external {
        count--;
    }
}
