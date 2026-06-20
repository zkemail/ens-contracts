// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Arrays } from "@openzeppelin/contracts/utils/Arrays.sol";
import { IDKIMRegistry } from "@zk-email/contracts/interfaces/IERC7969.sol";
import { NoirUtils } from "@zk-email/contracts/utils/NoirUtils.sol";
import { IVerifier } from "../interfaces/IVerifier.sol";
import { EnsUtils } from "../utils/EnsUtils.sol";
import { TextRecord } from "../entrypoints/LinkTextRecordEntrypoint.sol";

struct LinkHandleCommand {
    TextRecord textRecord;
    bytes proof;
    PublicInputs publicInputs;
}

struct PublicInputs {
    bytes32 pubkeyHash;
    bytes32 emailNullifier;
    bytes32 headerHash;
    address proverAddress;
    string command;
    string handle;
    string senderDomain;
}

abstract contract HandleVerifier is IVerifier {
    using Arrays for bytes32[];

    // #1: pubkey_hash -> 1 field -> idx 0
    uint256 public constant PUBKEY_HASH_OFFSET = 0;
    // #2: email_nullifier -> 1 field -> idx 1
    uint256 public constant EMAIL_NULLIFIER_OFFSET = 1;
    uint256 public constant EMAIL_NULLIFIER_NUM_FIELDS = 1;
    // #3: header_hash -> 2 fields -> idx 2-3
    uint256 public constant HEADER_HASH_OFFSET = 2;
    uint256 public constant HEADER_HASH_NUM_FIELDS = 2;
    // #4: prover_address -> 1 field -> idx 4
    uint256 public constant PROVER_ADDRESS_OFFSET = 4;
    uint256 public constant PROVER_ADDRESS_NUM_FIELDS = 1;
    // #5: command 20 fields -> idx 5-24 (605 bytes)
    uint256 public constant COMMAND_OFFSET = 5;
    uint256 public constant COMMAND_NUM_FIELDS = 20;
    // #6: x_handle_capture_1 64 fields + 1 field (length) = 65 fields -> idx 25-89
    uint256 public constant HANDLE_OFFSET = 25;
    uint256 public constant HANDLE_NUM_FIELDS = 65;
    // #7: sender_domain_capture_1 64 fields + 1 field (length) -> idx 90-154
    uint256 public constant SENDER_DOMAIN_OFFSET = 90;
    uint256 public constant SENDER_DOMAIN_NUM_FIELDS = 65;

    uint256 public constant PUBLIC_INPUTS_LENGTH = 155;

    address public immutable HONK_VERIFIER;
    address public immutable DKIM_REGISTRY;

    error InvalidPublicInputsLength();

    error InvalidDkimKeyHash();

    modifier onlyValidDkimKeyHash(string memory domainName, bytes32 dkimKeyHash) {
        if (!_isValidDkimKeyHash(domainName, dkimKeyHash)) revert InvalidDkimKeyHash();
        _;
    }

    constructor(address honkVerifier, address dkimRegistry) {
        HONK_VERIFIER = honkVerifier;
        DKIM_REGISTRY = dkimRegistry;
    }

    /**
     * @inheritdoc IVerifier
     */
    function dkimRegistryAddress() external view returns (address) {
        return DKIM_REGISTRY;
    }

    /**
     * @inheritdoc IVerifier
     */
    function verify(bytes memory data) external view virtual returns (bool);

    /**
     * @inheritdoc IVerifier
     */
    function encode(
        bytes calldata proof,
        bytes32[] calldata publicInputs
    )
        external
        pure
        virtual
        returns (bytes memory encodedCommand);

    function _isValidDkimKeyHash(string memory domainName, bytes32 dkimKeyHash) internal view returns (bool) {
        bytes32 domainHash = keccak256(bytes(domainName));
        return IDKIMRegistry(DKIM_REGISTRY).isKeyHashValid(domainHash, dkimKeyHash);
    }

    function _packPublicInputs(PublicInputs memory publicInputs) internal pure returns (bytes32[] memory fields) {
        fields = new bytes32[](PUBLIC_INPUTS_LENGTH);
        fields[PUBKEY_HASH_OFFSET] = publicInputs.pubkeyHash;
        fields[EMAIL_NULLIFIER_OFFSET] = publicInputs.emailNullifier;
        fields.replace(HEADER_HASH_OFFSET, EnsUtils.packHeaderHash(publicInputs.headerHash));
        fields.replace(
            PROVER_ADDRESS_OFFSET,
            NoirUtils.packFieldsArray(abi.encodePacked(publicInputs.proverAddress), PROVER_ADDRESS_NUM_FIELDS)
        );
        fields.replace(COMMAND_OFFSET, NoirUtils.packFieldsArray(bytes(publicInputs.command), COMMAND_NUM_FIELDS));
        fields.replace(HANDLE_OFFSET, NoirUtils.packBoundedVecU8(bytes(publicInputs.handle), HANDLE_NUM_FIELDS));
        fields.replace(
            SENDER_DOMAIN_OFFSET, NoirUtils.packBoundedVecU8(bytes(publicInputs.senderDomain), SENDER_DOMAIN_NUM_FIELDS)
        );
        return fields;
    }

    function _unpackPublicInputs(bytes32[] calldata fields) internal pure returns (PublicInputs memory publicInputs) {
        if (fields.length != PUBLIC_INPUTS_LENGTH) revert InvalidPublicInputsLength();

        return PublicInputs({
            pubkeyHash: fields[PUBKEY_HASH_OFFSET],
            emailNullifier: fields[EMAIL_NULLIFIER_OFFSET],
            headerHash: EnsUtils.unpackHeaderHash(
                fields.slice(HEADER_HASH_OFFSET, HEADER_HASH_OFFSET + HEADER_HASH_NUM_FIELDS)
            ),
            proverAddress: address(
                uint160(
                    bytes20(
                        NoirUtils.unpackFieldsArray(
                            fields.slice(PROVER_ADDRESS_OFFSET, PROVER_ADDRESS_OFFSET + PROVER_ADDRESS_NUM_FIELDS)
                        )
                    )
                )
            ),
            command: string(
                NoirUtils.unpackFieldsArray(fields.slice(COMMAND_OFFSET, COMMAND_OFFSET + COMMAND_NUM_FIELDS))
            ),
            handle: string(
                NoirUtils.unpackBoundedVecU8(fields.slice(HANDLE_OFFSET, HANDLE_OFFSET + HANDLE_NUM_FIELDS))
            ),
            senderDomain: string(
                NoirUtils.unpackBoundedVecU8(
                    fields.slice(SENDER_DOMAIN_OFFSET, SENDER_DOMAIN_OFFSET + SENDER_DOMAIN_NUM_FIELDS)
                )
            )
        });
    }

    function _copyTo(bytes32[] memory fields, uint256 offset, bytes32[] memory data) private pure {
        // solhint-disable-next-line no-inline-assembly
        assembly ("memory-safe") {
            mcopy(add(add(0x20, fields), mul(offset, 0x20)), add(0x20, data), mul(mload(data), 0x20))
        }
    }
}
