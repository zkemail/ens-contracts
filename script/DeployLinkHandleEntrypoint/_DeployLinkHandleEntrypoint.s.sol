// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Script, console } from "forge-std/Script.sol";
import { LinkHandleEntrypoint } from "../../src/entrypoints/LinkHandleEntrypoint.sol";
import { LinkHandleCommandVerifier } from "../../src/verifiers/LinkHandleCommandVerifier.sol";

abstract contract DeployLinkHandleEntrypointScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        console.log("\n=== Step 1: Deploy LinkHandleCommandVerifier ===");
        LinkHandleCommandVerifier commandVerifier =
            new LinkHandleCommandVerifier(_getHonkVerifierAddress(), _getDkimRegistryAddress());
        console.log("LinkHandleCommandVerifier deployed at:", address(commandVerifier));

        console.log("\n=== Step 2: Deploy LinkHandleEntrypoint ===");
        LinkHandleEntrypoint entrypoint =
            new LinkHandleEntrypoint(address(commandVerifier), _getRecordName(), _getPlatformName());
        console.log("LinkHandleEntrypoint deployed at:", address(entrypoint));

        vm.stopBroadcast();

        console.log("\n=== Deployment Complete ===");
        console.log("HONK_VERIFIER=", _getHonkVerifierAddress());
        console.log("DKIM_REGISTRY=", _getDkimRegistryAddress());
        console.log("LINK_HANDLE_COMMAND_VERIFIER=", address(commandVerifier));
        console.log("RECORD_NAME=", _getRecordName());
        console.log("PLATFORM_NAME=", _getPlatformName());
        console.log("LINK_HANDLE_ENTRYPOINT=", address(entrypoint));
    }

    /**
     * @notice The HonkVerifier address.
     * @dev TODO: ideally ths would be pure and would only return the address of the HonkVerifier deployed by the
     *          registry. Currently this is deployed inside this function. Remove it once the registry deploys the
     *          HonkVerifier.
     * @return The address of the HonkVerifier
     */
    function _getHonkVerifierAddress() internal virtual returns (address);

    /**
     * @notice The DKIM registry address.
     * @dev Example (sepolia): return 0xe24c24Ab94c93D5754De1cbE61b777e47cc57723;
     *      Example (sepolia always valid): return 0xc4f628496b8c474096650C8f9023954643cC614F;
     * @return The address of the DKIM registry
     */
    function _getDkimRegistryAddress() internal pure virtual returns (address);

    /**
     * @notice The platform name in the command (e.g. "x").
     * @return The platform name used in the command
     */
    function _getPlatformName() internal pure virtual returns (string memory);

    /**
     * @notice ENS text record name (e.g. "com.twitter") — the key in setText(node, key, value).
     * @return The record name for the text record
     */
    function _getRecordName() internal pure virtual returns (string memory);
}
