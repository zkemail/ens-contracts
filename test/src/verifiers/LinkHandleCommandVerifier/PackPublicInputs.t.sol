// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Test } from "forge-std/Test.sol";
import { LinkHandleCommandTestFixture } from "../../../fixtures/linkHandleCommand/LinkHandleCommandTestFixture.sol";
import { LinkHandleCommand } from "../../../../src/verifiers/HandleVerifier.sol";
import { LinkHandleCommandVerifierHelper } from "./_LinkHandleCommandVerifierHelper.sol";

contract PackPublicInputsTest is Test {
    LinkHandleCommandVerifierHelper internal _verifier;

    function setUp() public {
        address honkVerifier = makeAddr("honkVerifier");
        address dkimRegistry = makeAddr("dkimRegistry");
        _verifier = new LinkHandleCommandVerifierHelper(honkVerifier, dkimRegistry);
    }

    function test_correctlyPacksPublicInputsForLinkHandleCommand() public view {
        (LinkHandleCommand memory command, bytes32[] memory expectedPublicInputs) =
            LinkHandleCommandTestFixture.getTwitterFixture();
        bytes32[] memory publicInputs = _verifier.packPublicInputs(command.publicInputs);
        _assertEq(publicInputs, expectedPublicInputs);
    }

    function _assertEq(bytes32[] memory fields, bytes32[] memory expectedFields) internal pure {
        assertEq(keccak256(abi.encode(fields)), keccak256(abi.encode(expectedFields)));
    }
}
