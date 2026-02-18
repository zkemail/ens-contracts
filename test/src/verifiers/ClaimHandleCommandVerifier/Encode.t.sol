// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { HandleCommandTestFixture } from "../../../fixtures/handleCommand/HandleCommandTestFixture.sol";
import { HonkVerifier } from "../../../fixtures/linkHandleCommand/twitter/target/HonkVerifier.sol";
import {
    ClaimHandleCommand,
    ClaimHandleCommandVerifier,
    PublicInputs
} from "../../../../src/verifiers/ClaimHandleCommandVerifier.sol";
import { _EmailAuthVerifierTest } from "../EmailAuthVerifier/_EmailAuthVerifierTest.sol";

contract EncodeTest is _EmailAuthVerifierTest {
    ClaimHandleCommandVerifier internal _verifier;

    function setUp() public {
        _verifier = new ClaimHandleCommandVerifier(address(new HonkVerifier()), makeAddr("dkimRegistry"));
    }

    function test_correctlyEncodesAndDecodesCommand() public view {
        (ClaimHandleCommand memory command, bytes32[] memory expectedPublicInputs) =
            HandleCommandTestFixture.getClaimXFixture();

        bytes memory encodedData = _verifier.encode(command.proof, expectedPublicInputs);
        ClaimHandleCommand memory decodedCommand = abi.decode(encodedData, (ClaimHandleCommand));

        assertEq(decodedCommand.target, command.target);
        assertEq(decodedCommand.proof, command.proof, "proof mismatch");
        _assertEq(decodedCommand.publicInputs, command.publicInputs);
    }

    function test_encodeExtractsTargetFromCommandTemplate() public view {
        (ClaimHandleCommand memory command, bytes32[] memory expectedPublicInputs) =
            HandleCommandTestFixture.getClaimXFixture();

        // The encode function uses _getTemplate() to extract the target address from the command
        bytes memory encodedData = _verifier.encode(command.proof, expectedPublicInputs);
        ClaimHandleCommand memory decodedCommand = abi.decode(encodedData, (ClaimHandleCommand));

        // Verify the target was correctly extracted using the template "Withdraw all eth to {address}"
        assertTrue(decodedCommand.target != address(0), "Target should be extracted from command using template");
        assertEq(decodedCommand.target, command.target, "Target should match expected address from command");
    }

    function _assertEq(PublicInputs memory publicInputs, PublicInputs memory expectedPublicInputs) internal pure {
        assertEq(publicInputs.pubkeyHash, expectedPublicInputs.pubkeyHash, "pubkeyHash mismatch");
        assertEq(publicInputs.emailNullifier, expectedPublicInputs.emailNullifier, "nullifier mismatch");
        assertEq(publicInputs.headerHash, expectedPublicInputs.headerHash, "headerHash mismatch");
        assertEq(publicInputs.proverAddress, expectedPublicInputs.proverAddress, "proverAddress mismatch");
        assertEq(publicInputs.command, expectedPublicInputs.command, "command mismatch");
        assertEq(publicInputs.handle, expectedPublicInputs.handle, "handle mismatch");
        assertEq(publicInputs.senderDomain, expectedPublicInputs.senderDomain, "senderDomain mismatch");
    }
}
