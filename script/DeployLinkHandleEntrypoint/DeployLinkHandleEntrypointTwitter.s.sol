// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { DeployLinkHandleEntrypointScript } from "./_DeployLinkHandleEntrypoint.s.sol";
import { HonkVerifier } from "../../test/fixtures/handleCommand/HonkVerifier.sol";

contract DeployLinkHandleEntrypointTwitterScript is DeployLinkHandleEntrypointScript {
    function _deployHonkVerifier() internal override returns (address) {
        return address(new HonkVerifier());
    }

    function _dkimRegistry() internal pure override returns (address) {
        // sepolia always valid dkim registry
        return 0xc4f628496b8c474096650C8f9023954643cC614F;
    }

    function _keyName() internal pure override returns (string memory) {
        return "com.twitter";
    }
}
