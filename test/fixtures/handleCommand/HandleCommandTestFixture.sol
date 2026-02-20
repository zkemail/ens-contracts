// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Vm } from "forge-std/Vm.sol";
import { PublicInputs } from "../../../src/verifiers/HandleVerifier.sol";
import { ClaimHandleCommand } from "../../../src/verifiers/ClaimHandleCommandVerifier.sol";
import { TestStringUtils } from "../../utils/TestStringUtils.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

address constant _VM_ADDR = address(uint160(uint256(keccak256("hevm cheat code"))));
Vm constant vm = Vm(_VM_ADDR);

library HandleCommandTestFixture {
    using Strings for string;

    function getClaimXFixture()
        internal
        view
        returns (ClaimHandleCommand memory command, bytes32[] memory publicInputs)
    {
        string memory path = string.concat(vm.projectRoot(), "/test/fixtures/handleCommand/");

        PublicInputs memory expectedPublicInputs =
            _getExpectedPublicInputs(string.concat(path, "files/claimX/expected_public_inputs.json"));

        command = ClaimHandleCommand({
            target: Strings.parseAddress(TestStringUtils.getNthWord(expectedPublicInputs.command, -1)),
            proof: abi.encodePacked(_getProofFieldsFromBinary(string.concat(path, "files/claimX/proof"))),
            publicInputs: expectedPublicInputs
        });

        return (command, _getPublicInputsFieldsFromBinary(string.concat(path, "files/claimX/public_inputs")));
    }

    /**
     * @notice Reads the expected pub signals from a `expected_public_inputs.json` file (PublicInputs struct object)
     * @param path Path to the file  with the expected public inputs
     * @return publicInputs The PublicInputs struct object
     */
    function _getExpectedPublicInputs(string memory path) private view returns (PublicInputs memory publicInputs) {
        string memory publicInputsFile = vm.readFile(path);
        return PublicInputs({
            pubkeyHash: abi.decode(vm.parseJson(publicInputsFile, ".pubkeyHash"), (bytes32)),
            emailNullifier: abi.decode(vm.parseJson(publicInputsFile, ".emailNullifier"), (bytes32)),
            headerHash: abi.decode(vm.parseJson(publicInputsFile, ".headerHash"), (bytes32)),
            proverAddress: abi.decode(vm.parseJson(publicInputsFile, ".proverAddress"), (address)),
            command: abi.decode(vm.parseJson(publicInputsFile, ".command"), (string)),
            handle: abi.decode(vm.parseJson(publicInputsFile, ".handle"), (string)),
            senderDomain: abi.decode(vm.parseJson(publicInputsFile, ".senderDomain"), (string))
        });
    }

    /**
     * @notice Reads the proof from a `proof_fields.json` file (array of field / bytes32 values)
     * @param path Path to the file with the proof fields
     * @return proofFields The proof fields
     */
    function _getProofFields(string memory path) private view returns (bytes32[] memory proofFields) {
        bytes memory proofFieldsData = vm.parseJson(vm.readFile(path), ".");
        return abi.decode(proofFieldsData, (bytes32[]));
    }

    /**
     * @notice Reads the proof from a `proof` file (raw bytes of the proof)
     * @param path Path to the file with the proof fields
     * @return proofFields The proof fields
     */
    function _getProofFieldsFromBinary(string memory path) private view returns (bytes32[] memory proofFields) {
        // 1) Read the raw bytes
        bytes memory packed = vm.readFileBinary(path);

        // 2) Decode the blob into fixed bytes32[440]
        (bytes32[440] memory proofFixed) = abi.decode(packed, (bytes32[440]));

        // 3) Convert to dynamic bytes32[]
        proofFields = new bytes32[](440);
        for (uint256 i = 0; i < 440; i++) {
            proofFields[i] = proofFixed[i];
        }
        return proofFields;
    }

    /**
     * @notice Reads the public inputs from a `public_inputs_fields.json` file (array of field / bytes32 values)
     * @param path Path to the file with the public inputs fields
     * @return publicInputs The public inputs fields
     */
    function _getPublicInputsFields(string memory path) private view returns (bytes32[] memory publicInputs) {
        bytes memory publicInputsFieldsData = vm.parseJson(vm.readFile(path), ".");
        return abi.decode(publicInputsFieldsData, (bytes32[]));
    }

    /**
     * @notice Reads the public inputs from a `public_inputs_fields.json` file (array of field / bytes32 values)
     * @param path Path to the file with the public inputs fields
     * @return publicInputs The public inputs fields
     */
    function _getPublicInputsFieldsFromBinary(string memory path) private view returns (bytes32[] memory publicInputs) {
        // 1) Read the raw bytes
        bytes memory publicInputsFieldsData = vm.readFileBinary(path);

        // 2) Decode the blob into fixed bytes32[155]
        (bytes32[155] memory publicInputsFixed) = abi.decode(publicInputsFieldsData, (bytes32[155]));

        // 3) Convert to dynamic bytes32[]
        publicInputs = new bytes32[](155);
        for (uint256 i = 0; i < 155; i++) {
            publicInputs[i] = publicInputsFixed[i];
        }
        return publicInputs;
    }
}
