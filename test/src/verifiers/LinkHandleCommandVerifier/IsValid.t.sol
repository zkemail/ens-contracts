// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Test } from "forge-std/Test.sol";
import { LinkHandleCommandTestFixture } from "../../../fixtures/linkHandleCommand/LinkHandleCommandTestFixture.sol";
import { HonkVerifier } from "../../../fixtures/linkHandleCommand/twitter/target/HonkVerifier.sol";
import { LinkHandleCommand, LinkHandleCommandVerifier } from "../../../../src/verifiers/LinkHandleCommandVerifier.sol";
import { IDKIMRegistry } from "@zk-email/contracts/interfaces/IERC7969.sol";

contract IsValidTest is Test {
    LinkHandleCommandVerifier internal _verifier;

    function setUp() public {
        (LinkHandleCommand memory command,) = LinkHandleCommandTestFixture.getTwitterFixture();
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
        _verifier = new LinkHandleCommandVerifier(address(new HonkVerifier()), dkimRegistry);
    }

    // when verifier fails it reverts not returns false
    // expect revert for now
    // TODO: figure this out
    function test_revertsWhen_InvalidProof() public {
        (LinkHandleCommand memory command,) = LinkHandleCommandTestFixture.getTwitterFixture();
        bytes memory proof = new bytes(command.proof.length);
        proof[0] = command.proof[0] ^ bytes1(uint8(1));
        command.proof = proof;
        vm.expectRevert();
        _verifier.verify(abi.encode(command));
    }

    function test_returnsTrueForValidCommand() public view {
        (LinkHandleCommand memory command,) = LinkHandleCommandTestFixture.getTwitterFixture();
        bool isValid = _verifier.verify(abi.encode(command));
        assertTrue(isValid);
    }

    function test_returnsFalseForWrongENSName() public view {
        (LinkHandleCommand memory command,) = LinkHandleCommandTestFixture.getTwitterFixture();
        command.textRecord.ensName = "wrong.eth";
        bool isValid = _verifier.verify(abi.encode(command));
        assertFalse(isValid);
    }

    function test_returnsFalseForWrongHandle() public view {
        (LinkHandleCommand memory command,) = LinkHandleCommandTestFixture.getTwitterFixture();
        command.textRecord.value = "wrong";
        bool isValid = _verifier.verify(abi.encode(command));
        assertFalse(isValid);
    }
}
