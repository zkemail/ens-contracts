// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Test } from "forge-std/Test.sol";
import { TestStringUtils } from "./TestStringUtils.sol";
import { TestStringUtilsHelper } from "./_TestStringUtilsHelper.sol";

contract TestStringUtilsTest is Test {
    TestStringUtilsHelper internal _helper = new TestStringUtilsHelper();

    function test_getNthWord_outOfBoundsPositive_reverts() public {
        string memory input = "a b";

        vm.expectRevert(TestStringUtils.WordIndexOutOfBounds.selector);
        _helper.callGetNthWord(input, 2);
    }

    function test_getNthWord_outOfBoundsNegative_reverts() public {
        string memory input = "a b";

        vm.expectRevert(TestStringUtils.WordIndexOutOfBounds.selector);
        _helper.callGetNthWord(input, -3);
    }

    function test_getNthWord_emptyString_reverts() public {
        string memory input = "";

        vm.expectRevert(TestStringUtils.WordIndexOutOfBounds.selector);
        _helper.callGetNthWord(input, 0);
    }

    function test_getNthWord_positiveIndices() public view {
        string memory input = "a b c";

        assertEq(_helper.callGetNthWord(input, 0), "a");
        assertEq(_helper.callGetNthWord(input, 1), "b");
        assertEq(_helper.callGetNthWord(input, 2), "c");
    }

    function test_getNthWord_negativeIndices() public view {
        string memory input = "a b c";

        assertEq(_helper.callGetNthWord(input, -1), "c");
        assertEq(_helper.callGetNthWord(input, -2), "b");
        assertEq(_helper.callGetNthWord(input, -3), "a");
    }
}

