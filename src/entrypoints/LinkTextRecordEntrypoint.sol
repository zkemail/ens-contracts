// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { IEntryPoint } from "../interfaces/IEntryPoint.sol";
import { ITextRecordVerifier } from "../interfaces/ITextRecordVerifier.sol";
import { IVerifier } from "../interfaces/IVerifier.sol";
import { EnsUtils } from "../utils/EnsUtils.sol";

struct TextRecord {
    string platformName;
    string ensName;
    string value;
    bytes32 nullifier;
}

/**
 * @title LinkTextRecordEntrypoint
 * @notice Verifies a LinkTextRecordCommand and set the mapping of namehash(ensName) to text record.
 * @dev The verifier can be updated via the entrypoint function.
 */
abstract contract LinkTextRecordEntrypoint is IEntryPoint, ITextRecordVerifier {
    using EnsUtils for bytes;

    bytes32 private immutable _recordNameHash;
    bytes32 private immutable _platformNameHash;

    // link text record command verifier
    address public immutable VERIFIER;

    // can only be updated via the entrypoint function with a valid command
    mapping(bytes32 node => string textRecord) public textRecord;
    mapping(bytes32 nullifier => bool used) internal _isUsed;

    event TextRecordSet(bytes32 indexed node, string textRecord);

    error InvalidCommand();
    error NullifierUsed();

    /// @param recordName ENS text record name (e.g. "com.twitter") — the key in setText(node, key, value)
    /// @param platformName Platform name in the command (e.g. "x")
    constructor(address verifier, string memory recordName, string memory platformName) {
        VERIFIER = verifier;
        _recordNameHash = keccak256(bytes(recordName));
        _platformNameHash = bytes(platformName).length == 0 ? bytes32(0) : keccak256(bytes(platformName));
    }

    /**
     * @inheritdoc IEntryPoint
     * @dev Validates and extracts the text record from the data, verifies proof, then maps the ENS name hash to the
     * text record
     */
    function entrypoint(bytes memory data) external {
        TextRecord memory record = _extractTextRecord(data);

        if (_platformNameHash != bytes32(0) && keccak256(bytes(record.platformName)) != _platformNameHash) {
            revert InvalidCommand();
        }

        if (_isUsed[record.nullifier]) {
            revert NullifierUsed();
        }
        _isUsed[record.nullifier] = true;

        if (!IVerifier(VERIFIER).verify(data)) {
            revert InvalidCommand();
        }

        bytes32 node = bytes(record.ensName).namehash();
        textRecord[node] = record.value;
        emit TextRecordSet(node, record.value);
    }

    /**
     * @inheritdoc IEntryPoint
     * @dev Delegates encoding to the configured VERIFIER contract
     */
    function encode(bytes calldata proof, bytes32[] calldata publicInputs) external view returns (bytes memory) {
        return IVerifier(VERIFIER).encode(proof, publicInputs);
    }

    /**
     * @inheritdoc IEntryPoint
     * @dev Returns the address of the DKIM registry
     */
    function dkimRegistryAddress() external view returns (address) {
        return IVerifier(VERIFIER).dkimRegistryAddress();
    }

    /**
     * @inheritdoc ITextRecordVerifier
     */
    function verifyTextRecord(bytes32 node, string memory key, string memory value) external view returns (bool) {
        // this verifier only supports this specific text record (key must match constructor recordName)
        if (keccak256(bytes(key)) != _recordNameHash) {
            revert UnsupportedKey();
        }
        string memory storedTextRecord = textRecord[node];
        return keccak256(bytes(storedTextRecord)) == keccak256(bytes(value));
    }

    /**
     * @notice Extracts the text record from the data
     * @param data The data to extract the text record from
     * @return The text record (ensName, value, nullifier)
     */
    function _extractTextRecord(bytes memory data) internal virtual returns (TextRecord memory);
}
