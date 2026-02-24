// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Test } from "forge-std/Test.sol";
import { HandleCommandTestFixture } from "../../../fixtures/handleCommand/HandleCommandTestFixture.sol";
import { HonkVerifier } from "../../../fixtures/linkHandleCommand/twitter/target/HonkVerifier.sol";
import {
    ClaimHandleCommand,
    ClaimHandleCommandVerifier
} from "../../../../src/verifiers/ClaimHandleCommandVerifier.sol";
import { IDKIMRegistry } from "@zk-email/contracts/interfaces/IERC7969.sol";

contract IsValidTest is Test {
    ClaimHandleCommandVerifier internal _verifier;

    function setUp() public {
        (ClaimHandleCommand memory command,) = HandleCommandTestFixture.getClaimXFixture();
        address dkimRegistry = makeAddr("dkimRegistry");
        vm.mockCall(
            dkimRegistry,
            abi.encodeWithSelector(
                IDKIMRegistry.isKeyHashValid.selector,
                keccak256(bytes(command.publicInputs.senderDomain)),
                command.publicInputs.pubkeyHash
            ),
            abi.encode(true)
        );
        _verifier = new ClaimHandleCommandVerifier(address(new HonkVerifier()), dkimRegistry);
    }

    // when verifier fails it reverts not returns false
    // expect revert for now
    // TODO: figure this out
    function test_revertsWhen_InvalidProof() public {
        (ClaimHandleCommand memory command,) = HandleCommandTestFixture.getClaimXFixture();
        bytes memory proof = new bytes(command.proof.length);
        proof[0] = command.proof[0] ^ bytes1(uint8(1));
        command.proof = proof;
        vm.expectRevert();
        _verifier.verify(abi.encode(command));
    }

    function test_returnsTrueForValidCommand() public view {
        (ClaimHandleCommand memory command,) = HandleCommandTestFixture.getClaimXFixture();
        bool isValid = _verifier.verify(abi.encode(command));
        assertTrue(isValid);
    }

    function test_returnsFalseForWrongENSName() public view {
        (ClaimHandleCommand memory command,) = HandleCommandTestFixture.getClaimXFixture();
        command.target = address(0x123);
        bool isValid = _verifier.verify(abi.encode(command));
        assertFalse(isValid);
    }

    function test_returnsFalseForWrongHandle() public view {
        (ClaimHandleCommand memory command,) = HandleCommandTestFixture.getClaimXFixture();
        command.target = address(0x123);
        bool isValid = _verifier.verify(abi.encode(command));
        assertFalse(isValid);
    }
}
