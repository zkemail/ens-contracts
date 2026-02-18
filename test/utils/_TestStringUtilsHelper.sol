// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { TestStringUtils } from "./TestStringUtils.sol";

contract TestStringUtilsHelper {
    function callGetNthWord(string memory input, int256 n) external pure returns (string memory) {
        return TestStringUtils.getNthWord(input, n);
    }
}
