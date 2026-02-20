// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Script, console } from "forge-std/Script.sol";
import { HandleRegistrar } from "../src/entrypoints/HandleRegistrar.sol";
import { HandleResolver } from "../src/resolvers/HandleResolver.sol";
import { ClaimHandleCommandVerifier } from "../src/verifiers/ClaimHandleCommandVerifier.sol";
import { HonkVerifier } from "../test/fixtures/handleCommand/HonkVerifier.sol";
import { EnsUtils } from "../src/utils/EnsUtils.sol";

contract DeployAllDiscordScript is Script {
    using EnsUtils for bytes;

    // Sepolia always valid DKIM registry
    address public constant DKIM_REGISTRY = 0xc4f628496b8c474096650C8f9023954643cC614F;

    // Root ENS node for discord.zkemail.eth
    // This is namehash("discord.zkemail.eth")
    bytes32 public constant ROOT_NODE = 0xb657600555f5843da9cade4edffeb814c79d0635e75163d69116d923d386a147;

    // Existing resolver proxy on Sepolia
    address public constant RESOLVER_PROXY = 0xd72779845E642fbB8042d9E8EFc8f072355d9E53;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        console.log("\n=== Step 1: Deploy HandleRegistrar ===");

        // Deploy the HonkVerifier
        HonkVerifier honkVerifier = new HonkVerifier();
        console.log("HonkVerifier deployed at:", address(honkVerifier));

        // Deploy ClaimHandleCommandVerifier
        ClaimHandleCommandVerifier commandVerifier =
            new ClaimHandleCommandVerifier(address(honkVerifier), DKIM_REGISTRY);
        console.log("ClaimHandleCommandVerifier deployed at:", address(commandVerifier));

        // Deploy HandleRegistrar
        HandleRegistrar registrar = new HandleRegistrar(address(commandVerifier), ROOT_NODE);
        console.log("HandleRegistrar deployed at:", address(registrar));

        console.log("\n=== Step 2: Upgrade HandleResolver ===");

        // Deploy new resolver implementation
        HandleResolver newResolverImpl = new HandleResolver();
        console.log("New HandleResolver implementation deployed at:", address(newResolverImpl));

        // Upgrade the resolver proxy
        HandleResolver resolver = HandleResolver(RESOLVER_PROXY);
        resolver.upgradeToAndCall(address(newResolverImpl), "");
        console.log("Resolver upgraded successfully!");

        // Set the registrar on the resolver
        resolver.setRegistrar(address(registrar));
        console.log("Registrar set on resolver!");

        vm.stopBroadcast();

        console.log("\n=== Deployment Complete ===");
        console.log("DISCORD_HANDLE_REGISTRAR=", address(registrar));
        console.log("DISCORD_HANDLE_RESOLVER=", RESOLVER_PROXY);
        console.log("DISCORD_HANDLE_RESOLVER_NEW_IMPL=", address(newResolverImpl));
        console.log("CLAIM_DISCORD_HANDLE_VERIFIER=", address(commandVerifier));
        console.log("HONK_VERIFIER=", address(honkVerifier));
        console.log("DKIM_REGISTRY=", DKIM_REGISTRY);
        console.log("ROOT_NODE (discord.zkemail.eth)=", vm.toString(ROOT_NODE));

        console.log("\n=== Verification Commands ===");
        console.log("forge verify-contract", address(registrar), "src/entrypoints/HandleRegistrar.sol:HandleRegistrar");
        console.log(
            "  --constructor-args $(cast abi-encode 'constructor(address,bytes32)'",
            address(commandVerifier),
            vm.toString(ROOT_NODE),
            ")"
        );
        console.log(
            "\nforge verify-contract", address(newResolverImpl), "src/resolvers/HandleResolver.sol:HandleResolver"
        );
    }
}

