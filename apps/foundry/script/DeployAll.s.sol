// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {BaseDeployScript} from "./BaseDeployScript.sol";
import {Factory} from "../src/Factory.sol";
import {Committee} from "../src/Committee.sol";

/**
 * @title DeployAll
 * @notice Comprehensive deployment script for both Factory and a test Committee
 * @dev Deploys Factory first, then creates a Committee through it
 */
contract DeployAll is BaseDeployScript {
    Factory public factory;
    Committee public committee;

    // Test configuration
    uint256 constant TEST_CONTRIBUTION = 50e6; // 50 PyUSD
    uint256 constant TEST_COLLECTION_INTERVAL = 3 days;
    uint256 constant TEST_DISTRIBUTION_INTERVAL = 7 days;

    function run() public override broadcast {
        setUp();

        console.log("\n===========================================");
        console.log("Deploying Complete Committee System");
        console.log("===========================================\n");

        // Step 1: Deploy Factory
        deployFactory();

        // Step 2: Create a test Committee through Factory (optional)
        if (isLocalTestnet()) {
            console.log("\nTestnet detected - creating test committee...\n");
            createTestCommittee();
        }

        // Summary
        printDeploymentSummary();
    }

    function deployFactory() internal {
        console.log("Step 1: Deploying Factory");
        console.log("-------------------------------------------");

        // Check if already deployed
        if (!isLocalTestnet()) {
            address existingFactory = loadDeployment("Factory");
            if (existingFactory != address(0)) {
                console.log("Factory already deployed at:", existingFactory);
                factory = Factory(existingFactory);
                return;
            }
        }

        console.log("Deploying new Factory...");
        factory = new Factory(
            config.networkConfig.pyUsd,
            config.networkConfig.entropy,
            config.networkConfig.link,
            config.networkConfig.registrar,
            config.networkConfig.registry,
            config.networkConfig.uniswapRouter,
            config.networkConfig.weth,
            config.networkConfig.maxCommitteeMembers
        );

        console.log("Factory deployed at:", address(factory));
        saveDeployment("Factory", address(factory));
        console.log("");
    }

    function createTestCommittee() internal {
        console.log("Step 2: Creating Test Committee");
        console.log("-------------------------------------------");

        // Get test members
        address[] memory members = getTestMembers();

        console.log("Creating committee with", members.length, "members");
        console.log("Contribution:", TEST_CONTRIBUTION);
        console.log("Collection Interval:", TEST_COLLECTION_INTERVAL);
        console.log("Distribution Interval:", TEST_DISTRIBUTION_INTERVAL);

        // Create committee through factory
        address committeeAddress = factory.createCommittee(
            TEST_CONTRIBUTION, TEST_COLLECTION_INTERVAL, TEST_DISTRIBUTION_INTERVAL, members, config.deployer
        );

        committee = Committee(payable(committeeAddress));
        console.log("Test Committee created at:", address(committee));
        saveDeployment("TestCommittee", address(committee));
        console.log("");
    }

    function getTestMembers() internal returns (address[] memory) {
        // Try environment variables first
        try vm.envAddress("TEST_MEMBER_1") returns (address member1) {
            uint256 memberCount = vm.envOr("TEST_MEMBER_COUNT", uint256(3));
            address[] memory members = new address[](memberCount);

            for (uint256 i = 0; i < memberCount; i++) {
                string memory envVar = string.concat("TEST_MEMBER_", vm.toString(i + 1));
                members[i] = vm.envAddress(envVar);
            }
            return members;
        } catch {
            // Use default addresses
            address[] memory members = new address[](3);
            members[0] = makeAddr("testMember1");
            members[1] = makeAddr("testMember2");
            members[2] = makeAddr("testMember3");
            return members;
        }
    }

    function printDeploymentSummary() internal view {
        console.log("\n===========================================");
        console.log("DEPLOYMENT SUMMARY");
        console.log("===========================================");
        console.log("Network:", config.network);
        console.log("Chain ID:", config.chainId);
        console.log("Deployer:", config.deployer);
        console.log("");
        console.log("Contracts Deployed:");
        console.log("-------------------------------------------");
        console.log("Factory:", address(factory));
        if (address(committee) != address(0)) {
            console.log("Test Committee:", address(committee));
        }
        console.log("");
        console.log("Configuration:");
        console.log("-------------------------------------------");
        console.log("PyUSD:", config.networkConfig.pyUsd);
        console.log("Entropy:", config.networkConfig.entropy);
        console.log("LINK:", config.networkConfig.link);
        console.log("Registrar:", config.networkConfig.registrar);
        console.log("Registry:", config.networkConfig.registry);
        console.log("Uniswap Router:", config.networkConfig.uniswapRouter);
        console.log("WETH:", config.networkConfig.weth);
        console.log("===========================================\n");

        if (address(committee) != address(0)) {
            console.log("Next Steps:");
            console.log("1. Fund committee automation:");
            console.log("   cast send", vm.toString(address(committee)));
            console.log("   \"fundAutomation(uint256)\" 50 --value 1ether --private-key $PRIVATE_KEY");
            console.log("");
            console.log("2. Check upkeep status:");
            console.log("   cast call", vm.toString(address(committee)));
            console.log("   \"getUpkeepId()\"");
            console.log("");
        }

        console.log("3. Create new committees:");
        console.log("   cast send", vm.toString(address(factory)));
        console.log("   \"createCommittee(uint256,uint256,uint256,address[],address)\"");
        console.log("   [contribution] [collection] [distribution] [members] [multisig]");
        console.log("");
    }
}
