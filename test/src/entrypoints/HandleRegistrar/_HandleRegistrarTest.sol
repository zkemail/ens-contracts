// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Test } from "forge-std/Test.sol";
import { HandleRegistrarHelper } from "./_HandleRegistrarHelper.sol";
import { HandleCommandTestFixture } from "../../../fixtures/handleCommand/HandleCommandTestFixture.sol";
import { HonkVerifier } from "../../../fixtures/linkHandleCommand/twitter/target/HonkVerifier.sol";
import {
    ClaimHandleCommand,
    ClaimHandleCommandVerifier
} from "../../../../src/verifiers/ClaimHandleCommandVerifier.sol";
import { IDKIMRegistry } from "@zk-email/contracts/interfaces/IERC7969.sol";
import { EnsUtils } from "../../../../src/utils/EnsUtils.sol";

abstract contract HandleRegistrarTest is Test {
    using EnsUtils for bytes;

    HandleRegistrarHelper internal _registrar;
    ClaimHandleCommandVerifier internal _verifier;
    address internal _dkimRegistry;
    bytes32 internal _rootNode;

    ClaimHandleCommand internal _validCommand;
    bytes internal _validEncodedCommand;
    bytes32 internal _ensNode;

    function setUp() public virtual {
        // Get the valid command from fixture
        (_validCommand,) = HandleCommandTestFixture.getClaimXFixture();

        // Setup DKIM registry mock
        _dkimRegistry = makeAddr("dkimRegistry");
        vm.mockCall(
            _dkimRegistry,
            abi.encodeWithSelector(
                IDKIMRegistry.isKeyHashValid.selector,
                keccak256(bytes(_validCommand.publicInputs.senderDomain)),
                _validCommand.publicInputs.pubkeyHash
            ),
            abi.encode(true)
        );

        // Calculate root node: namehash("x.zkemail.eth")
        _rootNode = bytes("x.zkemail.eth").namehash();

        // Deploy verifier and registrar
        _verifier = new ClaimHandleCommandVerifier(address(new HonkVerifier()), _dkimRegistry);
        _registrar = new HandleRegistrarHelper(address(_verifier), _rootNode);

        // Calculate ENS node from handle: namehash("handle.x.zkemail.eth")
        // Note: Must lowercase the handle first, as the registrar does
        string memory lowercaseHandle = _toLowercase(_validCommand.publicInputs.handle);
        bytes32 labelHash = keccak256(bytes(lowercaseHandle));
        _ensNode = keccak256(abi.encodePacked(_rootNode, labelHash));
        _validEncodedCommand = abi.encode(_validCommand);
    }

    /**
     * @dev Helper function to convert string to lowercase for ENS node calculation
     */
    function _toLowercase(string memory str) internal pure returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);

        for (uint256 i = 0; i < bStr.length; i++) {
            // If uppercase letter (A-Z is 65-90 in ASCII)
            if (bStr[i] >= 0x41 && bStr[i] <= 0x5A) {
                // Convert to lowercase by adding 32
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }

        return string(bLower);
    }
}

