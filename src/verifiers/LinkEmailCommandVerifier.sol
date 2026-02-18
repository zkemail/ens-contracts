// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { CircomUtils } from "@zk-email/contracts/utils/CircomUtils.sol";
import { CommandUtils } from "@zk-email/email-tx-builder/src/libraries/CommandUtils.sol";
import { Bytes } from "@openzeppelin/contracts/utils/Bytes.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { EmailAuthVerifier, EmailAuthProof, PublicInputs } from "./EmailAuthVerifier.sol";
import { TextRecord } from "../entrypoints/LinkTextRecordEntrypoint.sol";

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

struct LinkEmailCommand {
    TextRecord textRecord;
    EmailAuthProof emailAuthProof;
}

contract LinkEmailCommandVerifier is EmailAuthVerifier {
    using Bytes for bytes;
    using Strings for string;
    using CircomUtils for bytes;

    constructor(address _groth16Verifier, address _dkimRegistry) EmailAuthVerifier(_groth16Verifier, _dkimRegistry) { }

    /**
     * @inheritdoc EmailAuthVerifier
     */
    function verify(bytes memory data) external view override returns (bool) {
        return _isValid(abi.decode(data, (LinkEmailCommand)));
    }

    /**
     * @inheritdoc EmailAuthVerifier
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
        return abi.encode(_buildLinkEmailCommand(proof, publicInputs));
    }

    function _isValid(LinkEmailCommand memory command)
        internal
        view
        onlyValidDkimKeyHash(
            command.emailAuthProof.publicInputs.domainName, command.emailAuthProof.publicInputs.publicKeyHash
        )
        returns (bool)
    {
        PublicInputs memory publicInputs = command.emailAuthProof.publicInputs;
        return _verifyEmailProof(GORTH16_VERIFIER, command.emailAuthProof)
            && Strings.equal(command.textRecord.value, publicInputs.emailAddress)
            && Strings.equal(_getMaskedCommand(command), publicInputs.maskedCommand);
    }

    /**
     * @notice Reconstructs a LinkEmailCommand struct from proof bytes and public inputs fields.
     */
    function _buildLinkEmailCommand(
        bytes memory proof,
        bytes32[] calldata publicInputsFields
    )
        private
        pure
        returns (LinkEmailCommand memory command)
    {
        PublicInputs memory publicInputs = _unpackPublicInputs(publicInputsFields);
        return LinkEmailCommand({
            textRecord: TextRecord({
                platformName: string(
                    CommandUtils.extractCommandParamByIndex(
                        _getTemplate(), publicInputs.maskedCommand, uint256(CommandParamIndex.PLATFORM_NAME)
                    )
                ),
                // ensName is extracted from the command
                ensName: string(
                    CommandUtils.extractCommandParamByIndex(
                        _getTemplate(), publicInputs.maskedCommand, uint256(CommandParamIndex.ENS_NAME)
                    )
                ),
                // emailAddress is the value
                value: publicInputs.emailAddress,
                // emailNullifier is the nullifier
                nullifier: publicInputs.emailNullifier
            }),
            emailAuthProof: EmailAuthProof({ proof: proof, publicInputs: publicInputs })
        });
    }

    function _getMaskedCommand(LinkEmailCommand memory command) private pure returns (string memory) {
        bytes[] memory commandParams = new bytes[](2);
        commandParams[0] = abi.encode(command.textRecord.platformName);
        commandParams[1] = abi.encode(command.textRecord.ensName);

        return CommandUtils.computeExpectedCommand(commandParams, _getTemplate(), 0);
    }

    function _getTemplate() private pure returns (string[] memory template) {
        template = new string[](5);

        template[0] = "Link";
        template[1] = "my";
        template[2] = CommandUtils.STRING_MATCHER;
        template[3] = "to";
        template[4] = CommandUtils.STRING_MATCHER;

        return template;
    }
}
