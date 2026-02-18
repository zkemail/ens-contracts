// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { CommandUtils } from "@zk-email/email-tx-builder/src/libraries/CommandUtils.sol";
import { IHonkVerifier } from "../interfaces/IHonkVerifier.sol";

import { HandleVerifier, LinkHandleCommand, PublicInputs, TextRecord } from "./HandleVerifier.sol";

/**
 * @notice Enum representing the indices of command parameters in the command template
 * @dev Used to specify which parameter to extract from the command string
 * @param PLATFORM_NAME = 0
 * @param ENS_NAME = 1
 */
enum CommandParamIndex {
    PLATFORM_NAME,
    ENS_NAME
}

contract LinkHandleCommandVerifier is HandleVerifier {
    constructor(address honkVerifier, address dkimRegistry) HandleVerifier(honkVerifier, dkimRegistry) { }

    /**
     * @inheritdoc HandleVerifier
     */
    function verify(bytes memory data) external view override returns (bool) {
        return _isValid(abi.decode(data, (LinkHandleCommand)));
    }

    /**
     * @inheritdoc HandleVerifier
     */
    function encode(
        bytes calldata proof,
        bytes32[] calldata publicInputs
    )
        external
        pure
        override
        returns (bytes memory encodedCommand)
    {
        return abi.encode(_buildLinkHandleCommand(proof, publicInputs));
    }

    function _isValid(LinkHandleCommand memory command)
        internal
        view
        onlyValidDkimKeyHash(command.publicInputs.senderDomain, command.publicInputs.pubkeyHash)
        returns (bool)
    {
        PublicInputs memory publicInputs = command.publicInputs;

        return IHonkVerifier(HONK_VERIFIER).verify(command.proof, _packPublicInputs(publicInputs))
            && Strings.equal(command.textRecord.value, publicInputs.handle)
            && Strings.equal(_getCommand(command), publicInputs.command);
    }

    function _buildLinkHandleCommand(
        bytes calldata proof,
        bytes32[] calldata publicInputsFields
    )
        private
        pure
        returns (LinkHandleCommand memory command)
    {
        PublicInputs memory publicInputs = _unpackPublicInputs(publicInputsFields);
        return LinkHandleCommand({
            textRecord: TextRecord({
                platformName: string(
                    CommandUtils.extractCommandParamByIndex(
                        _getTemplate(), publicInputs.command, uint256(CommandParamIndex.PLATFORM_NAME)
                    )
                ),
                // ensName is extracted from the command
                ensName: string(
                    CommandUtils.extractCommandParamByIndex(
                        _getTemplate(), publicInputs.command, uint256(CommandParamIndex.ENS_NAME)
                    )
                ),
                // handle is the value
                value: publicInputs.handle,
                nullifier: publicInputs.emailNullifier
            }),
            proof: proof,
            publicInputs: publicInputs
        });
    }

    function _getCommand(LinkHandleCommand memory command) private pure returns (string memory) {
        bytes[] memory commandParams = new bytes[](2);
        commandParams[0] = abi.encode(command.textRecord.platformName);
        commandParams[1] = abi.encode(command.textRecord.ensName);

        return CommandUtils.computeExpectedCommand(commandParams, _getTemplate(), 0);
    }

    function _getTemplate() private pure returns (string[] memory template) {
        template = new string[](6);

        template[0] = "Link";
        template[1] = "my";
        template[2] = CommandUtils.STRING_MATCHER;
        template[3] = "handle";
        template[4] = "to";
        template[5] = CommandUtils.STRING_MATCHER;

        return template;
    }
}
