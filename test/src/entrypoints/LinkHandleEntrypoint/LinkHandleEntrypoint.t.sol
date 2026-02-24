// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Test } from "forge-std/Test.sol";
import { LinkHandleCommand } from "../../../../src/verifiers/HandleVerifier.sol";
import { LinkHandleCommandVerifier } from "../../../../src/verifiers/LinkHandleCommandVerifier.sol";
import { HonkVerifier } from "../../../fixtures/linkHandleCommand/twitter/target/HonkVerifier.sol";
import { EnsUtils } from "../../../../src/utils/EnsUtils.sol";
import { LinkHandleEntrypointHelper } from "./_LinkHandleEntrypointHelper.sol";
import { LinkTextRecordEntrypoint } from "../../../../src/entrypoints/LinkTextRecordEntrypoint.sol";
import { ITextRecordVerifier } from "../../../../src/interfaces/ITextRecordVerifier.sol";
import { LinkHandleCommandTestFixture } from "../../../fixtures/linkHandleCommand/LinkHandleCommandTestFixture.sol";
import { IDKIMRegistry } from "@zk-email/contracts/interfaces/IERC7969.sol";

contract LinkHandleVerifierTest is Test {
    using EnsUtils for bytes;

    string public constant RECORD_NAME = "com.twitter";
    string public constant PLATFORM_NAME = "x";

    LinkHandleCommandVerifier public verifier;
    LinkHandleEntrypointHelper public linkHandle;

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
        verifier = new LinkHandleCommandVerifier(address(new HonkVerifier()), dkimRegistry);
        linkHandle = new LinkHandleEntrypointHelper(address(verifier), RECORD_NAME, PLATFORM_NAME);
    }

    function test_entrypoint_correctlyEncodesAndValidatesCommand() public {
        (LinkHandleCommand memory command, bytes32[] memory expectedPublicInputs) =
            LinkHandleCommandTestFixture.getTwitterFixture();

        bytes memory encodedCommand = linkHandle.encode(command.proof, expectedPublicInputs);
        assertEq(linkHandle.textRecord(bytes(command.textRecord.ensName).namehash()), "");
        linkHandle.entrypoint(encodedCommand);
        assertEq(linkHandle.isUsed(command.publicInputs.emailNullifier), true);
        assertEq(linkHandle.textRecord(bytes(command.textRecord.ensName).namehash()), command.textRecord.value);
    }

    function test_entrypoint_revertsWhenNullifierIsUsed() public {
        (LinkHandleCommand memory command, bytes32[] memory expectedPublicInputs) =
            LinkHandleCommandTestFixture.getTwitterFixture();
        bytes memory encodedCommand = linkHandle.encode(command.proof, expectedPublicInputs);
        linkHandle.entrypoint(encodedCommand);
        vm.expectRevert(abi.encodeWithSelector(LinkTextRecordEntrypoint.NullifierUsed.selector));
        linkHandle.entrypoint(encodedCommand);
    }

    function test_entrypoint_revertsWhenPlatformNameMismatch() public {
        (LinkHandleCommand memory command, bytes32[] memory expectedPublicInputs) =
            LinkHandleCommandTestFixture.getTwitterFixture();
        // Entrypoint configured for "discord" but command has platformName "x" (from fixture)
        LinkHandleEntrypointHelper discordEntrypoint =
            new LinkHandleEntrypointHelper(address(verifier), RECORD_NAME, "discord");
        bytes memory encodedCommand = discordEntrypoint.encode(command.proof, expectedPublicInputs);
        vm.expectRevert(abi.encodeWithSelector(LinkTextRecordEntrypoint.InvalidCommand.selector));
        discordEntrypoint.entrypoint(encodedCommand);
    }

    function test_verifyTextRecord_revertsWhenKeyIsUnsupported() public {
        (LinkHandleCommand memory command,) = LinkHandleCommandTestFixture.getTwitterFixture();
        bytes32 node = bytes(command.textRecord.ensName).namehash();
        vm.expectRevert(abi.encodeWithSelector(ITextRecordVerifier.UnsupportedKey.selector));
        linkHandle.verifyTextRecord(node, "com.discord", command.textRecord.value);
    }

    function test_verifyTextRecord_returnsFalseWhenTextRecordIsIncorrect() public {
        (LinkHandleCommand memory command, bytes32[] memory expectedPublicInputs) =
            LinkHandleCommandTestFixture.getTwitterFixture();
        bytes memory encodedCommand = linkHandle.encode(command.proof, expectedPublicInputs);
        linkHandle.entrypoint(encodedCommand);
        assertEq(
            linkHandle.verifyTextRecord(bytes(command.textRecord.ensName).namehash(), RECORD_NAME, "incorrect"), false
        );
    }

    function test_verifyTextRecord_returnsTrueWhenTextRecordIsCorrect() public {
        (LinkHandleCommand memory command, bytes32[] memory expectedPublicInputs) =
            LinkHandleCommandTestFixture.getTwitterFixture();
        bytes memory encodedCommand = linkHandle.encode(command.proof, expectedPublicInputs);
        linkHandle.entrypoint(encodedCommand);
        assertEq(
            linkHandle.verifyTextRecord(
                bytes(command.textRecord.ensName).namehash(), RECORD_NAME, command.textRecord.value
            ),
            true
        );
    }
}
