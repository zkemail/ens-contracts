// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Script, console } from "forge-std/Script.sol";
import { HandleRegistrar } from "../src/entrypoints/HandleRegistrar.sol";
import { HandleResolver } from "../src/resolvers/HandleResolver.sol";
import { ClaimHandleCommandVerifier } from "../src/verifiers/ClaimHandleCommandVerifier.sol";
import { HonkVerifier } from "../test/fixtures/redditHandleCommand/HonkVerifier.sol";
import { EnsUtils } from "../src/utils/EnsUtils.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployAllRedditScript is Script {
    using EnsUtils for bytes;

    // Sepolia always valid DKIM registry
    address public constant DKIM_REGISTRY = 0xc4f628496b8c474096650C8f9023954643cC614F;

    // Root ENS node for reddit.zkemail.eth
    // This is namehash("reddit.zkemail.eth")
    bytes32 public constant ROOT_NODE = 0x842a604b9359cbd77b6d5aeb06922ba11be02d7e32734c85ffa118d80869f9ee;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        console.log("\n=== Step 1: Deploy HandleRegistrar ===");

        // Deploy the HonkVerifier
        HonkVerifier honkVerifier = new HonkVerifier();
        console.log("HonkVerifier deployed at:", address(honkVerifier));

        // Deploy ClaimHandleCommandVerifier
        ClaimHandleCommandVerifier claimHandleCommandVerifier =
            new ClaimHandleCommandVerifier(address(honkVerifier), DKIM_REGISTRY);
        console.log("ClaimHandleCommandVerifier deployed at:", address(claimHandleCommandVerifier));

        // Deploy HandleRegistrar
        HandleRegistrar handleRegistrar = new HandleRegistrar(address(claimHandleCommandVerifier), ROOT_NODE);
        console.log("HandleRegistrar deployed at:", address(handleRegistrar));

        console.log("\n=== Step 2: Upgrade HandleResolver ===");

        // Deploy resolver implementation
        HandleResolver handleResolverImpl = new HandleResolver();
        console.log("HandleResolver implementation deployed at:", address(handleResolverImpl));

        // Encode resolver initializer function call
        bytes memory handleResolverInitData =
            abi.encodeWithSelector(HandleResolver.initialize.selector, address(handleRegistrar));

        // Deploy HandleResolver proxy
        ERC1967Proxy handleResolverProxy = new ERC1967Proxy(address(handleResolverImpl), handleResolverInitData);
        console.log("HandleResolver proxy deployed at:", address(handleResolverProxy));

        vm.stopBroadcast();

        console.log("\n=== Deployment Complete ===");
        console.log("REDDIT_HANDLE_REGISTRAR=", address(handleRegistrar));
        console.log("REDDIT_HANDLE_RESOLVER_PROXY=", address(handleResolverProxy));
        console.log("REDDIT_HANDLE_RESOLVER_IMPLEMENTATION=", address(handleResolverImpl));
        console.log("CLAIM_REDDIT_HANDLE_VERIFIER=", address(claimHandleCommandVerifier));
        console.log("HONK_VERIFIER=", address(honkVerifier));
        console.log("DKIM_REGISTRY=", DKIM_REGISTRY);
        console.log("ROOT_NODE (reddit.zkemail.eth)=", vm.toString(ROOT_NODE));

        console.log("\n=== Verification Commands ===");
        console.log(
            "forge verify-contract", address(handleRegistrar), "src/entrypoints/HandleRegistrar.sol:HandleRegistrar"
        );
        console.log(
            "  --constructor-args $(cast abi-encode 'constructor(address,bytes32)'",
            address(claimHandleCommandVerifier),
            vm.toString(ROOT_NODE),
            ")"
        );
        console.log(
            "\nforge verify-contract", address(handleResolverImpl), "src/resolvers/HandleResolver.sol:HandleResolver"
        );
    }
}

