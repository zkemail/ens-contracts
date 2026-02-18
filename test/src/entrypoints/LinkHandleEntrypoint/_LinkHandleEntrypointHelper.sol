// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { LinkHandleEntrypoint } from "../../../../src/entrypoints/LinkHandleEntrypoint.sol";

contract LinkHandleEntrypointHelper is LinkHandleEntrypoint {
    constructor(
        address verifier,
        string memory recordName,
        string memory platformName
    )
        LinkHandleEntrypoint(verifier, recordName, platformName)
    { }

    function isUsed(bytes32 nullifier) public view returns (bool) {
        return _isUsed[nullifier];
    }
}
