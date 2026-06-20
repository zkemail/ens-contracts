// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Arrays } from "@openzeppelin/contracts/utils/Arrays.sol";
import { CircomUtils } from "@zk-email/contracts/utils/CircomUtils.sol";
import { IDKIMRegistry } from "@zk-email/contracts/interfaces/IERC7969.sol";
import { IGroth16Verifier } from "../interfaces/IGroth16Verifier.sol";
import { IVerifier } from "../interfaces/IVerifier.sol";
import { EnsUtils } from "../utils/EnsUtils.sol";

struct EmailAuthProof {
    bytes proof;
    PublicInputs publicInputs;
}

struct PublicInputs {
    string domainName;
    bytes32 publicKeyHash;
    bytes32 emailNullifier;
    uint256 timestamp;
    string maskedCommand;
    bytes32 accountSalt;
    bool isCodeExist;
    bytes miscellaneousData;
    string emailAddress;
}

/**
 * @title EmailAuthVerifier
 * @notice This abstract contract provides the core logic for verifying EmailAuth circuit  proofs.
 * @dev It defines the public signals' structure and offers internal functions to pack, unpack, and verify them
 * against a Groth16 proof. The public signals are laid out in a fixed 60-element array, with each segment
 * corresponding to a specific piece of data extracted from the email.
 *
 * The public inputs array (`publicInputs`) is structured as follows:
 *       ----------------------------------------------------------------------------------------------------------
 *      | Range   | #Fields | Field Name          | Description                                                    |
 *      |---------|---------|---------------------|----------------------------------------------------------------|
 *      | 0-8     | 9       | domainName          | Packed string of the sender's domain name.                     |
 *      | 9       | 1       | publicKeyHash       | The hash of the DKIM RSA public key.                           |
 *      | 10      | 1       | emailNullifier      | A unique identifier to prevent replay attacks.                 |
 *      | 11      | 1       | timestamp           | The email's timestamp. Defaults to 0 if not available.         |
 *      | 12-31   | 20      | maskedCommand       | The packed string of the command extracted from the email.     |
 *      | 32      | 1       | accountSalt         | An optional salt for added security.                           |
 *      | 33      | 1       | isCodeExist         | A boolean flag indicating if a verification code is present.   |
 *      | 34-50   | 17      | miscellaneousData   | Auxiliary data, typically the decomposed DKIM public key.      |
 *      | 51-59   | 9       | emailAddress        | The packed string of the sender's full email address.          |
 *       ----------------------------------------------------------------------------------------------------------
 */
abstract contract EmailAuthVerifier is IVerifier {
    using Arrays for bytes32[];

    /// @notice The order of the BN128 elliptic curve used in the ZK proofs
    /// @dev All field elements in proofs must be less than this value
    uint256 public constant Q =
        21_888_242_871_839_275_222_246_405_745_257_275_088_696_311_157_297_823_662_689_037_894_645_226_208_583;

    // #1: domain_name CEIL(255 bytes / 31 bytes per field) = 9 fields -> idx 0-8
    uint256 public constant DOMAIN_NAME_OFFSET = 0;
    uint256 public constant DOMAIN_NAME_NUM_FIELDS = 9;
    uint256 public constant DOMAIN_NAME_PADDED_SIZE = 255;
    // #2: public_key_hash 32 bytes -> 1 field -> idx 9
    uint256 public constant PUBLIC_KEY_HASH_OFFSET = 9;
    uint256 public constant PUBLIC_KEY_HASH_NUM_FIELDS = 1;
    // #3: email_nullifier 32 bytes -> 1 field -> idx 10
    uint256 public constant EMAIL_NULLIFIER_OFFSET = 10;
    uint256 public constant EMAIL_NULLIFIER_NUM_FIELDS = 1;
    // #4: timestamp 32 bytes -> 1 field -> idx 11
    uint256 public constant TIMESTAMP_OFFSET = 11;
    uint256 public constant TIMESTAMP_NUM_FIELDS = 1;
    // #5: masked_command CEIL(605 bytes / 31 bytes per field) = 20 fields -> idx 12-31
    uint256 public constant MASKED_COMMAND_OFFSET = 12;
    uint256 public constant MASKED_COMMAND_SIZE = 605;
    uint256 public constant MASKED_COMMAND_NUM_FIELDS = 20;
    // #6: account_salt 32 bytes -> 1 field -> idx 32
    uint256 public constant ACCOUNT_SALT_OFFSET = 32;
    uint256 public constant ACCOUNT_SALT_NUM_FIELDS = 1;
    // #7: is_code_exist 1 byte -> 1 field -> idx 33
    uint256 public constant IS_CODE_EXIST_OFFSET = 33;
    uint256 public constant IS_CODE_EXIST_NUM_FIELDS = 1;
    // #8: pubkey -> 17 fields -> idx 34-50
    uint256 public constant MISCELLANEOUS_DATA_OFFSET = 34;
    uint256 public constant MISCELLANEOUS_DATA_SIZE = 17;
    uint256 public constant MISCELLANEOUS_DATA_NUM_FIELDS = 17;
    // #9: email_address CEIL(256 bytes / 31 bytes per field) = 9 fields -> idx 51-59
    uint256 public constant EMAIL_ADDRESS_OFFSET = 51;
    uint256 public constant EMAIL_ADDRESS_PADDED_SIZE = 256;
    uint256 public constant EMAIL_ADDRESS_NUM_FIELDS = 9;

    uint256 public constant PUBLIC_INPUTS_LENGTH = 60;

    address public immutable GORTH16_VERIFIER;
    address public immutable DKIM_REGISTRY;

    error InvalidDkimKeyHash();

    /**
     * @notice Ensures the provided DKIM public key hash is valid for the given domain
     */
    modifier onlyValidDkimKeyHash(string memory domainName, bytes32 dkimKeyHash) {
        if (!_isValidDkimKeyHash(domainName, dkimKeyHash)) revert InvalidDkimKeyHash();
        _;
    }

    constructor(address groth16Verifier, address dkimRegistry) {
        GORTH16_VERIFIER = groth16Verifier;
        DKIM_REGISTRY = dkimRegistry;
    }

    /**
     * @inheritdoc IVerifier
     */
    function verify(bytes memory data) external view virtual returns (bool);

    /**
     * @inheritdoc IVerifier
     */
    function encode(bytes calldata proof, bytes32[] calldata publicInputs) external view virtual returns (bytes memory);

    /**
     * @inheritdoc IVerifier
     */
    function dkimRegistryAddress() external view returns (address) {
        return DKIM_REGISTRY;
    }

    /**
     * @notice Verifies the validity of the DKIM public key hash
     * @param domainName The domain name of the email
     * @param dkimKeyHash The hash of the DKIM public key
     * @return isValid True if the public key hash is valid, false otherwise
     */
    function _isValidDkimKeyHash(string memory domainName, bytes32 dkimKeyHash) internal view returns (bool) {
        bytes32 domainHash = keccak256(bytes(domainName));
        return IDKIMRegistry(DKIM_REGISTRY).isKeyHashValid(domainHash, dkimKeyHash);
    }

    /**
     * @notice Verifies the validity of an EmailAuthProof
     * @param groth16Verifier The address of the Groth16Verifier contract
     * @param emailAuthProof The EmailAuthProof struct containing the proof and PublicInputs struct
     * @return isValid True if the proof is valid, false otherwise
     */
    function _verifyEmailProof(
        address groth16Verifier,
        EmailAuthProof memory emailAuthProof
    )
        internal
        view
        returns (bool isValid)
    {
        // decode the proof
        (uint256[2] memory pA, uint256[2][2] memory pB, uint256[2] memory pC) =
            abi.decode(emailAuthProof.proof, (uint256[2], uint256[2][2], uint256[2]));

        // check if all values are less than Q (max value of bn128 curve)
        bool validFieldElements =
            (pA[0] < Q && pA[1] < Q && pB[0][0] < Q && pB[0][1] < Q && pB[1][0] < Q && pB[1][1] < Q && pC[0] < Q
                && pC[1] < Q);

        if (!validFieldElements) {
            return false;
        }

        bytes32[] memory publicInputsFields = _packPublicInputs(emailAuthProof.publicInputs);

        // convert to uint256[60] memory
        uint256[PUBLIC_INPUTS_LENGTH] memory pubSignals;
        for (uint256 i = 0; i < PUBLIC_INPUTS_LENGTH; i++) {
            pubSignals[i] = uint256(publicInputsFields[i]);
        }

        // verify the proof
        bool validProof = IGroth16Verifier(groth16Verifier).verifyProof(pA, pB, pC, pubSignals);

        return validProof;
    }

    /**
     * @notice Packs the PublicInputs struct into the public inputs array
     * @param publicInputs The PublicInputs struct
     * @return fields The packed public inputs array
     */
    function _packPublicInputs(PublicInputs memory publicInputs) internal pure returns (bytes32[] memory fields) {
        fields = new bytes32[](PUBLIC_INPUTS_LENGTH);
        fields.replace(
            DOMAIN_NAME_OFFSET, CircomUtils.packFieldsArray(bytes(publicInputs.domainName), DOMAIN_NAME_PADDED_SIZE)
        );
        fields[PUBLIC_KEY_HASH_OFFSET] = publicInputs.publicKeyHash;
        fields[EMAIL_NULLIFIER_OFFSET] = publicInputs.emailNullifier;
        fields[TIMESTAMP_OFFSET] = bytes32(publicInputs.timestamp);
        fields.replace(
            MASKED_COMMAND_OFFSET, CircomUtils.packFieldsArray(bytes(publicInputs.maskedCommand), MASKED_COMMAND_SIZE)
        );
        fields[ACCOUNT_SALT_OFFSET] = publicInputs.accountSalt;
        fields.replace(IS_CODE_EXIST_OFFSET, CircomUtils.packBool(publicInputs.isCodeExist));
        fields.replace(MISCELLANEOUS_DATA_OFFSET, EnsUtils.packPubKey(publicInputs.miscellaneousData));
        fields.replace(
            EMAIL_ADDRESS_OFFSET,
            CircomUtils.packFieldsArray(bytes(publicInputs.emailAddress), EMAIL_ADDRESS_PADDED_SIZE)
        );

        return fields;
    }

    /**
     * @notice Unpacks the public inputs and proof into a PublicInputs struct
     * @param fields Array of public inputs fields
     * @return publicInputs The PublicInputs struct, with each field extracted from the public inputs fields
     */
    function _unpackPublicInputs(bytes32[] calldata fields) internal pure returns (PublicInputs memory publicInputs) {
        if (fields.length != PUBLIC_INPUTS_LENGTH) revert CircomUtils.InvalidPublicInputsLength();

        return PublicInputs({
            domainName: string(
                CircomUtils.unpackFieldsArray(
                    fields.slice(DOMAIN_NAME_OFFSET, DOMAIN_NAME_OFFSET + DOMAIN_NAME_NUM_FIELDS),
                    DOMAIN_NAME_PADDED_SIZE
                )
            ),
            publicKeyHash: fields[PUBLIC_KEY_HASH_OFFSET],
            emailNullifier: fields[EMAIL_NULLIFIER_OFFSET],
            timestamp: uint256(fields[TIMESTAMP_OFFSET]),
            maskedCommand: string(
                CircomUtils.unpackFieldsArray(
                    fields.slice(MASKED_COMMAND_OFFSET, MASKED_COMMAND_OFFSET + MASKED_COMMAND_NUM_FIELDS),
                    MASKED_COMMAND_SIZE
                )
            ),
            accountSalt: fields[ACCOUNT_SALT_OFFSET],
            isCodeExist: CircomUtils.unpackBool(
                fields.slice(IS_CODE_EXIST_OFFSET, IS_CODE_EXIST_OFFSET + IS_CODE_EXIST_NUM_FIELDS)
            ),
            miscellaneousData: EnsUtils.unpackPubKey(fields, MISCELLANEOUS_DATA_OFFSET),
            emailAddress: string(
                CircomUtils.unpackFieldsArray(
                    fields.slice(EMAIL_ADDRESS_OFFSET, EMAIL_ADDRESS_OFFSET + EMAIL_ADDRESS_NUM_FIELDS),
                    EMAIL_ADDRESS_PADDED_SIZE
                )
            )
        });
    }
}
