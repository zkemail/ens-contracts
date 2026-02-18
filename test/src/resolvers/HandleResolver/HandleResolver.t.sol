// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Test } from "forge-std/Test.sol";
import { HandleRegistrar } from "../../../../src/entrypoints/HandleRegistrar.sol";
import { HandleResolver } from "../../../../src/resolvers/HandleResolver.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { ITextResolver } from "@ensdomains/ens-contracts/contracts/resolvers/profiles/ITextResolver.sol";
import { IAddrResolver } from "@ensdomains/ens-contracts/contracts/resolvers/profiles/IAddrResolver.sol";
import { NameCoder } from "@ensdomains/ens-contracts/contracts/utils/NameCoder.sol";
import { ClaimHandleCommandVerifier } from "../../../../src/verifiers/ClaimHandleCommandVerifier.sol";
import { HonkVerifier } from "../../../fixtures/linkHandleCommand/twitter/target/HonkVerifier.sol";
import { EnsUtils } from "../../../../src/utils/EnsUtils.sol";

contract HandleResolverTest is Test {
    using EnsUtils for bytes;

    HandleResolver public resolver;
    HandleResolver public implementation;
    ERC1967Proxy public proxy;
    address public owner;

    HandleRegistrar public registrar;
    bytes32 public rootNode;

    function setUp() public {
        owner = address(this);

        // Deploy implementation
        implementation = new HandleResolver();

        // Deploy proxy
        bytes memory initData = abi.encodeWithSelector(HandleResolver.initialize.selector, address(0));
        proxy = new ERC1967Proxy(address(implementation), initData);

        // Cast proxy to HandleResolver interface
        resolver = HandleResolver(address(proxy));
    }

    function testUpgrade() public {
        // Deploy new implementation
        HandleResolver newImplementation = new HandleResolver();

        // Upgrade
        resolver.upgradeToAndCall(address(newImplementation), "");

        // Verify upgrade worked - resolver should still be functional
        bytes memory name = NameCoder.encode("test.platform.zkemail.eth");
        bytes memory data = abi.encodeWithSelector(ITextResolver.text.selector, bytes32(0), "description");

        bytes memory result = resolver.resolve(name, data);
        string memory description = abi.decode(result, (string));

        assertEq(description, "Claim your tips from the zkEmail dashboard");
    }

    function testUpgradeOnlyOwner() public {
        HandleResolver newImplementation = new HandleResolver();

        // Try to upgrade from non-owner account
        vm.prank(address(0x123));
        vm.expectRevert();
        resolver.upgradeToAndCall(address(newImplementation), "");
    }

    function testResolveAddr() public {
        bytes memory name = NameCoder.encode("test.platform.zkemail.eth");
        bytes memory data = abi.encodeWithSelector(IAddrResolver.addr.selector, bytes32(0));

        // Should revert because registrar is not set (initialized with address(0))
        vm.expectRevert(abi.encodeWithSignature("RegistrarNotSet()"));
        resolver.resolve(name, data);
    }

    function testResolveAddrWithRegistrar() public {
        // Deploy a registrar
        address dkimRegistry = makeAddr("dkimRegistry");
        ClaimHandleCommandVerifier verifier = new ClaimHandleCommandVerifier(address(new HonkVerifier()), dkimRegistry);
        rootNode = bytes("x.zkemail.eth").namehash();
        registrar = new HandleRegistrar(address(verifier), rootNode);

        // Set the registrar on the resolver
        resolver.setRegistrar(address(registrar));

        // Test resolving an address for a specific handle
        string memory handle = "thezdev1";
        string memory ensName = string(abi.encodePacked(handle, ".x.zkemail.eth"));
        bytes memory dnsName = NameCoder.encode(ensName);

        // Calculate the ENS node
        bytes32 labelHash = keccak256(bytes(handle));
        bytes32 ensNode = keccak256(abi.encodePacked(rootNode, labelHash));

        // Get predicted address from registrar
        address predictedAddr = registrar.predictAddress(ensNode);

        // Resolve address through resolver
        bytes memory addrData = abi.encodeWithSelector(IAddrResolver.addr.selector, ensNode);
        bytes memory result = resolver.resolve(dnsName, addrData);
        address resolvedAddr = abi.decode(result, (address));

        // Verify they match
        assertEq(resolvedAddr, predictedAddr, "Resolver should return registrar's predicted address");
        assertTrue(resolvedAddr != address(0), "Resolved address should not be zero");
    }

    function testResolveUnsupportedSelector() public {
        bytes memory name = NameCoder.encode("test.platform.zkemail.eth");
        // Use a random unsupported selector
        bytes4 unsupported = bytes4(keccak256("unsupported()"));
        bytes memory data = abi.encodePacked(unsupported, bytes32(0));

        vm.expectRevert(abi.encodeWithSelector(HandleResolver.UnsupportedResolverProfile.selector, unsupported));
        resolver.resolve(name, data);
    }

    function testInitialization() public view {
        assertEq(resolver.owner(), owner);
    }

    function testResolveTextDescription() public view {
        bytes memory name = NameCoder.encode("test.platform.zkemail.eth");
        bytes memory data = abi.encodeWithSelector(ITextResolver.text.selector, bytes32(0), "description");

        bytes memory result = resolver.resolve(name, data);
        string memory description = abi.decode(result, (string));

        assertEq(description, "Claim your tips from the zkEmail dashboard");
    }

    function testResolveTextUrl() public view {
        bytes memory name = NameCoder.encode("myhandle.platform.zkemail.eth");
        bytes memory data = abi.encodeWithSelector(ITextResolver.text.selector, bytes32(0), "url");

        bytes memory result = resolver.resolve(name, data);
        string memory url = abi.decode(result, (string));

        assertEq(url, "https://zk.email/myhandle.platform.zkemail.eth");
    }

    function testSupportsInterface() public view {
        // Test IExtendedResolver interface
        bytes4 extendedResolverInterface = 0x9061b923; // IExtendedResolver interfaceId
        assertTrue(resolver.supportsInterface(extendedResolverInterface));
    }

    function testResolveTextUnknownKey() public view {
        bytes memory name = NameCoder.encode("test.platform.zkemail.eth");
        bytes memory data = abi.encodeWithSelector(ITextResolver.text.selector, bytes32(0), "unknownKey");

        bytes memory result = resolver.resolve(name, data);
        string memory value = abi.decode(result, (string));

        assertEq(value, "", "Unknown text key should return empty string");
    }
}

