// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {BaseDeployScript} from "./BaseDeployScript.sol";
import {Committee} from "../src/Committee.sol";

/**
 * @title DeployCommittee
 * @notice Deployment script for standalone Committee contract (for testing)
 * @dev Supports Arbitrum, Arbitrum Sepolia, and Anvil
 * @dev In production, committees should be created through the Factory
 */
contract DeployCommittee is BaseDeployScript {
    Committee public committee;

    // Default test configuration
    uint256 constant DEFAULT_CONTRIBUTION = 100e6; // 100 PyUSD
    uint256 constant DEFAULT_COLLECTION_INTERVAL = 7 days;
    uint256 constant DEFAULT_DISTRIBUTION_INTERVAL = 14 days;

    function run() public override broadcast {
        setUp();

        console.log("\n===========================================");
        console.log("Deploying Committee Contract (Test)");
        console.log("===========================================\n");

        // Get test members from environment or use defaults
        address[] memory members = getTestMembers();

        console.log("Configuration:");
        console.log("- Contribution Amount:", DEFAULT_CONTRIBUTION);
        console.log("- Collection Interval:", DEFAULT_COLLECTION_INTERVAL);
        console.log("- Distribution Interval:", DEFAULT_DISTRIBUTION_INTERVAL);
        console.log("- Number of Members:", members.length);
        console.log("- Total Cycles:", members.length);
        console.log("");

        // Create committee config
        Committee.CommitteeConfig memory committeeConfig = Committee.CommitteeConfig({
            contributionAmount: DEFAULT_CONTRIBUTION,
            collectionInterval: DEFAULT_COLLECTION_INTERVAL,
            distributionInterval: DEFAULT_DISTRIBUTION_INTERVAL,
            members: members
        });

        // Create external contracts config
        Committee.ExternalContracts memory externalContracts = Committee.ExternalContracts({
            pyUsd: config.networkConfig.pyUsd,
            entropy: config.networkConfig.entropy,
            link: config.networkConfig.link,
            registrar: config.networkConfig.registrar,
            registry: config.networkConfig.registry,
            weth: config.networkConfig.weth
        });

        // Deploy Committee
        console.log("Deploying Committee...");
        committee = new Committee(
            committeeConfig,
            externalContracts,
            config.deployer // multisig owner
        );

        console.log("\n===========================================");
        console.log("Deployment Successful!");
        console.log("===========================================");
        console.log("Committee deployed at:", address(committee));
        console.log("Committee owner:", committee.owner());
        console.log("Total cycles:", committee.i_totalCycles());
        console.log("Contribution amount:", committee.i_contributionAmount());
        console.log("===========================================\n");

        // Save deployment
        saveDeployment("Committee", address(committee));

        // Display members
        console.log("Committee Members:");
        for (uint256 i = 0; i < members.length; i++) {
            console.log(i + 1, "-", members[i]);
        }
        console.log("");

        // Instructions
        console.log("Next Steps:");
        console.log("1. Fund the committee for automation:");
        console.log("   cast send", vm.toString(address(committee)));
        console.log("   \"fundAutomation(uint256)\" 50 --value 1ether");
        console.log("");
        console.log("2. Members can deposit contributions:");
        console.log("   cast send", vm.toString(address(committee)));
        console.log("   \"depositContribution(uint256)\"", DEFAULT_CONTRIBUTION);
        console.log("");
    }

    function getTestMembers() internal returns (address[] memory) {
        // Try to load members from environment
        try vm.envAddress("COMMITTEE_MEMBER_1") returns (address member1) {
            address[] memory members = new address[](5);
            members[0] = member1;
            members[1] = vm.envAddress("COMMITTEE_MEMBER_2");
            members[2] = vm.envAddress("COMMITTEE_MEMBER_3");
            members[3] = vm.envAddress("COMMITTEE_MEMBER_4");
            members[4] = vm.envAddress("COMMITTEE_MEMBER_5");
            return members;
        } catch {
            // Use default test members
            console.log("Using default test members (update .env with COMMITTEE_MEMBER_X)");
            address[] memory members = new address[](3);
            members[0] = makeAddr("alice");
            members[1] = makeAddr("bob");
            members[2] = makeAddr("charlie");
            return members;
        }
    }
}
