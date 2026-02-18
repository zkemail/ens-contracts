// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Script, console } from "forge-std/Script.sol";
import { LinkHandleEntrypoint } from "../src/entrypoints/LinkHandleEntrypoint.sol";
import { LinkHandleCommandVerifier } from "../src/verifiers/LinkHandleCommandVerifier.sol";
import { HonkVerifier } from "../test/fixtures/handleCommand/HonkVerifier.sol";

contract DeployLinkHandleEntrypointScript is Script {
    // sepolia
    // address public constant DKIM_REGISTRY = 0xe24c24Ab94c93D5754De1cbE61b777e47cc57723;
    // sepolia always valid dkim registry
    address public constant DKIM_REGISTRY = 0xc4f628496b8c474096650C8f9023954643cC614F;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        LinkHandleCommandVerifier commandVerifier =
            new LinkHandleCommandVerifier(address(new HonkVerifier()), DKIM_REGISTRY);
        LinkHandleEntrypoint verifier = new LinkHandleEntrypoint(address(commandVerifier), "com.twitter");
        vm.stopBroadcast();

        console.log("LINK_HANDLE_VERIFIER=", address(verifier));
    }
}
