// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Test } from "forge-std/Test.sol";
import { TestFixtures } from "../../../fixtures/TestFixtures.sol";
import { LinkEmailCommand, LinkEmailCommandVerifier } from "../../../../src/verifiers/LinkEmailCommandVerifier.sol";
import { Groth16Verifier } from "../../../fixtures/Groth16Verifier.sol";
import { EnsUtils } from "../../../../src/utils/EnsUtils.sol";
import { LinkEmailEntrypointHelper } from "./_LinkEmailEntrypointHelper.sol";
import { LinkTextRecordEntrypoint } from "../../../../src/entrypoints/LinkTextRecordEntrypoint.sol";
import { ITextRecordVerifier } from "../../../../src/interfaces/ITextRecordVerifier.sol";
import { IDKIMRegistry } from "@zk-email/contracts/interfaces/IERC7969.sol";

contract LinkEmailEntrypointTest is Test {
    using EnsUtils for bytes;

    LinkEmailCommandVerifier public verifier;
    LinkEmailEntrypointHelper public linkEmail;

    function setUp() public {
        (LinkEmailCommand memory command,) = TestFixtures.linkEmailCommand();
        address dkimRegistry = makeAddr("dkimRegistry");
        vm.mockCall(
            dkimRegistry,
            abi.encodeWithSelector(
                IDKIMRegistry.isKeyHashValid.selector,
                keccak256(bytes(command.emailAuthProof.publicInputs.domainName)),
                command.emailAuthProof.publicInputs.publicKeyHash
            ),
            abi.encode(true)
        );
        verifier = new LinkEmailCommandVerifier(address(new Groth16Verifier()), dkimRegistry);
        linkEmail = new LinkEmailEntrypointHelper(address(verifier));
    }

    function test_entrypoint_correctlyEncodesAndValidatesCommand() public {
        (LinkEmailCommand memory command, bytes32[] memory expectedPublicInputs) = TestFixtures.linkEmailCommand();

        bytes memory encodedCommand = linkEmail.encode(command.emailAuthProof.proof, expectedPublicInputs);
        assertEq(linkEmail.textRecord(bytes(command.textRecord.ensName).namehash()), "");
        linkEmail.entrypoint(encodedCommand);
        assertEq(linkEmail.isUsed(command.emailAuthProof.publicInputs.emailNullifier), true);
        assertEq(linkEmail.textRecord(bytes(command.textRecord.ensName).namehash()), command.textRecord.value);
    }

    function test_entrypoint_revertsWhenNullifierIsUsed() public {
        (LinkEmailCommand memory command, bytes32[] memory expectedPublicInputs) = TestFixtures.linkEmailCommand();
        bytes memory encodedCommand = linkEmail.encode(command.emailAuthProof.proof, expectedPublicInputs);
        linkEmail.entrypoint(encodedCommand);
        vm.expectRevert(abi.encodeWithSelector(LinkTextRecordEntrypoint.NullifierUsed.selector));
        linkEmail.entrypoint(encodedCommand);
    }

    function test_verifyTextRecord_revertsWhenKeyIsUnsupported() public {
        (LinkEmailCommand memory command,) = TestFixtures.linkEmailCommand();
        bytes32 node = bytes(command.textRecord.ensName).namehash();
        vm.expectRevert(abi.encodeWithSelector(ITextRecordVerifier.UnsupportedKey.selector));
        linkEmail.verifyTextRecord(node, "com.twitter", command.textRecord.value);
    }

    function test_verifyTextRecord_returnsTrueWhenTextRecordIsCorrect() public {
        (LinkEmailCommand memory command, bytes32[] memory expectedPublicInputs) = TestFixtures.linkEmailCommand();
        bytes memory encodedCommand = linkEmail.encode(command.emailAuthProof.proof, expectedPublicInputs);
        linkEmail.entrypoint(encodedCommand);
        assertEq(
            linkEmail.verifyTextRecord(bytes(command.textRecord.ensName).namehash(), "email", command.textRecord.value),
            true
        );
    }

    function test_verifyTextRecord_returnsFalseWhenTextRecordIsIncorrect() public {
        (LinkEmailCommand memory command, bytes32[] memory expectedPublicInputs) = TestFixtures.linkEmailCommand();
        bytes memory encodedCommand = linkEmail.encode(command.emailAuthProof.proof, expectedPublicInputs);
        linkEmail.entrypoint(encodedCommand);
        assertEq(
            linkEmail.verifyTextRecord(bytes(command.textRecord.ensName).namehash(), "email", "incorrect@e.com"), false
        );
    }
}
