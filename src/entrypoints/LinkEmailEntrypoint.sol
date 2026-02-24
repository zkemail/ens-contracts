// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { LinkTextRecordEntrypoint, TextRecord } from "./LinkTextRecordEntrypoint.sol";
import { LinkEmailCommand } from "../verifiers/LinkEmailCommandVerifier.sol";

/**
 * @title LinkEmailEntrypoint
 * @notice Verifies a LinkEmailCommand and set the mapping of namehash(ensName) to email address.
 * @dev The verifier can be updated via the entrypoint function.
 */
contract LinkEmailEntrypoint is LinkTextRecordEntrypoint {
    constructor(address verifier) LinkTextRecordEntrypoint(verifier, "email", "email") { }

    /**
     * @inheritdoc LinkTextRecordEntrypoint
     * @dev Specifically decodes data as LinkEmailCommand and returns text record (ensName, emailAddress, nullifier)
     */
    function _extractTextRecord(bytes memory data) internal pure override returns (TextRecord memory) {
        LinkEmailCommand memory command = abi.decode(data, (LinkEmailCommand));

        return command.textRecord;
    }
}
