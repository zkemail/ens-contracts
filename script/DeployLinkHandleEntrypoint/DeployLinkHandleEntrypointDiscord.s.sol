// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { DeployLinkHandleEntrypointScript } from "./_DeployLinkHandleEntrypoint.s.sol";
import { HonkVerifier } from "../../test/fixtures/linkHandleCommand/discord/target/HonkVerifier.sol";

contract DeployLinkHandleEntrypointDiscordScript is DeployLinkHandleEntrypointScript {
    function _deployHonkVerifier() internal override returns (address) {
        return address(new HonkVerifier());
    }

    function _getDkimRegistryAddress() internal pure override returns (address) {
        // sepolia always valid dkim registry
        return 0xc4f628496b8c474096650C8f9023954643cC614F;
    }

    function _getPlatformName() internal pure override returns (string memory) {
        return "Discord";
    }

    function _getRecordName() internal pure override returns (string memory) {
        return "com.discord";
    }
}
