// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Script } from "forge-std/Script.sol";
import { LinkHandleEntrypoint } from "../src/entrypoints/LinkHandleEntrypoint.sol";
import { LinkHandleCommand } from "../src/verifiers/HandleVerifier.sol";
import { LinkHandleCommandTestFixture } from "../test/fixtures/linkHandleCommand/LinkHandleCommandTestFixture.sol";

contract LinkHandleWithFixtureScript is Script {
    // sepolia mock
    address public constant DKIM_REGISTRY = 0xec22Ad55d5D26F1DAB8D020FEBb423C03f535D40;
    // sepolia
    address public constant LINK_X_HANDLE_VERIFIER = 0x8cd219dEb66E9f7d20eB489EA464751F8F26Ea07;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        LinkHandleEntrypoint verifier = LinkHandleEntrypoint(LINK_X_HANDLE_VERIFIER);
        (LinkHandleCommand memory command,) = LinkHandleCommandTestFixture.getTwitterFixture();

        vm.startBroadcast(deployerPrivateKey);

        verifier.entrypoint(abi.encode(command));

        vm.stopBroadcast();
    }
}
