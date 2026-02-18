// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Script, console } from "forge-std/Script.sol";
import { LinkHandleEntrypoint } from "../../src/entrypoints/LinkHandleEntrypoint.sol";
import { LinkHandleCommandVerifier } from "../../src/verifiers/LinkHandleCommandVerifier.sol";

abstract contract DeployLinkHandleEntrypointScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        console.log("\n=== Step 1: Deploy HonkVerifier ===");

        address honkVerifier = _deployHonkVerifier();
        console.log("HonkVerifier deployed at:", address(honkVerifier));

        console.log("\n=== Step 2: Deploy LinkHandleCommandVerifier ===");
        LinkHandleCommandVerifier commandVerifier = new LinkHandleCommandVerifier(honkVerifier, _dkimRegistry());
        console.log("LinkHandleCommandVerifier deployed at:", address(commandVerifier));

        console.log("\n=== Step 3: Deploy LinkHandleEntrypoint ===");
        LinkHandleEntrypoint verifier =
            new LinkHandleEntrypoint(address(commandVerifier), _recordName(), _platformName());
        console.log("LinkHandleEntrypoint deployed at:", address(verifier));

        vm.stopBroadcast();

        console.log("\n=== Deployment Complete ===");
        console.log("HONK_VERIFIER=", address(honkVerifier));
        console.log("RECORD_NAME=", _recordName());
        console.log("LINK_HANDLE_VERIFIER=", address(verifier));
    }

    /**
     * @notice Deploys the HonkVerifier. This is needed because each platform has its own HonkVerifier generated from
     * the circuit.
     * @dev Example: return address(new HonkVerifier());
     * @return The address of the HonkVerifier
     */
    function _deployHonkVerifier() internal virtual returns (address);

    /**
     * @notice The DKIM registry address.
     * @dev Example (sepolia): return 0xe24c24Ab94c93D5754De1cbE61b777e47cc57723;
     *      Example (sepolia always valid): return 0xc4f628496b8c474096650C8f9023954643cC614F;
     * @return The address of the DKIM registry
     */
    function _dkimRegistry() internal pure virtual returns (address);

    /**
     * @notice ENS text record name (e.g. "com.twitter") — the key in setText(node, key, value).
     * @return The record name for the text record
     */
    function _recordName() internal pure virtual returns (string memory);

    /**
     * @notice The platform name in the command (e.g. "x").
     * @return The platform name used in the command
     */
    function _platformName() internal pure virtual returns (string memory);
}
