// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Vm } from "forge-std/Vm.sol";
import { LinkHandleCommand, PublicInputs } from "../../../src/verifiers/HandleVerifier.sol";
import { TextRecord } from "../../../src/entrypoints/LinkTextRecordEntrypoint.sol";
import { TestStringUtils } from "../../utils/TestStringUtils.sol";

address constant _LINK_HANDLE_VM_ADDR = address(uint160(uint256(keccak256("hevm cheat code"))));
Vm constant linkHandleVm = Vm(_LINK_HANDLE_VM_ADDR);

/**
 * @title LinkHandleCommandTestFixture
 * @notice Provides link-handle command fixtures per platform (e.g. Twitter/X).
 * @dev Each platform has a dedicated getter; add fixture data under test/fixtures/linkHandleCommand/<platform>/files/
 *      (expected_public_inputs.json, proof, public_inputs, email.eml) to enable that platform.
 */
library LinkHandleCommandTestFixture {
    function getTwitterFixture()
        internal
        view
        returns (LinkHandleCommand memory command, bytes32[] memory publicInputs)
    {
        return getFixture("twitter");
    }

    /**
     * @notice Load link-handle fixture for a given platform subdir (e.g. "twitter", "discord").
     * @param platform Subdir name under test/fixtures/linkHandleCommand/
     */
    function getFixture(string memory platform)
        internal
        view
        returns (LinkHandleCommand memory command, bytes32[] memory publicInputs)
    {
        string memory path =
            string.concat(linkHandleVm.projectRoot(), "/test/fixtures/linkHandleCommand/", platform, "/");

        PublicInputs memory expectedPublicInputs =
            _getExpectedPublicInputs(string.concat(path, "files/expected_public_inputs.json"));

        command = LinkHandleCommand({
            textRecord: TextRecord({
                platformName: TestStringUtils.getNthWord(expectedPublicInputs.command, 2),
                ensName: TestStringUtils.getNthWord(expectedPublicInputs.command, -1),
                value: expectedPublicInputs.handle,
                nullifier: expectedPublicInputs.emailNullifier
            }),
            proof: abi.encodePacked(_getProofFieldsFromBinary(string.concat(path, "files/proof"))),
            publicInputs: expectedPublicInputs
        });

        return (command, _getPublicInputsFieldsFromBinary(string.concat(path, "files/public_inputs")));
    }

    function _getExpectedPublicInputs(string memory path) private view returns (PublicInputs memory publicInputs) {
        string memory publicInputsFile = linkHandleVm.readFile(path);
        return PublicInputs({
            pubkeyHash: abi.decode(linkHandleVm.parseJson(publicInputsFile, ".pubkeyHash"), (bytes32)),
            emailNullifier: abi.decode(linkHandleVm.parseJson(publicInputsFile, ".emailNullifier"), (bytes32)),
            headerHash: abi.decode(linkHandleVm.parseJson(publicInputsFile, ".headerHash"), (bytes32)),
            proverAddress: abi.decode(linkHandleVm.parseJson(publicInputsFile, ".proverAddress"), (address)),
            command: abi.decode(linkHandleVm.parseJson(publicInputsFile, ".command"), (string)),
            handle: abi.decode(linkHandleVm.parseJson(publicInputsFile, ".handle"), (string)),
            senderDomain: abi.decode(linkHandleVm.parseJson(publicInputsFile, ".senderDomain"), (string))
        });
    }

    function _getProofFieldsFromBinary(string memory path) private view returns (bytes32[] memory proofFields) {
        bytes memory packed = linkHandleVm.readFileBinary(path);
        (bytes32[440] memory proofFixed) = abi.decode(packed, (bytes32[440]));
        proofFields = new bytes32[](440);
        for (uint256 i = 0; i < 440; i++) {
            proofFields[i] = proofFixed[i];
        }
        return proofFields;
    }

    function _getPublicInputsFieldsFromBinary(string memory path) private view returns (bytes32[] memory publicInputs) {
        bytes memory publicInputsFieldsData = linkHandleVm.readFileBinary(path);
        (bytes32[155] memory publicInputsFixed) = abi.decode(publicInputsFieldsData, (bytes32[155]));
        publicInputs = new bytes32[](155);
        for (uint256 i = 0; i < 155; i++) {
            publicInputs[i] = publicInputsFixed[i];
        }
        return publicInputs;
    }
}
