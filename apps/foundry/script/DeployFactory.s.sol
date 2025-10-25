// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {BaseDeployScript} from "./BaseDeployScript.sol";
import {Factory} from "../src/Factory.sol";
import {CommitteeDeployer} from "../src/CommitteeDeployer.sol";

/**
 * @title DeployFactory
 * @notice Deployment script for the Factory contract
 * @dev Supports Arbitrum, Arbitrum Sepolia, and Anvil
 */
contract DeployFactory is BaseDeployScript {
    Factory public factory;

    function run() public override broadcast {
        setUp();

        console.log("\n===========================================");
        console.log("Deploying Factory Contract");
        console.log("===========================================\n");

        // Check if Factory already deployed
        address existingFactory = loadDeployment("Factory");
        if (existingFactory != address(0)) {
            console.log("Factory already deployed at:", existingFactory);
            console.log("Skipping deployment. Delete the deployment file to redeploy.");
            return;
        }

        // Log configuration
        console.log("Configuration:");
        console.log("- PyUSD:", config.networkConfig.pyUsd);
        console.log("- Entropy:", config.networkConfig.entropy);
        console.log("- LINK:", config.networkConfig.link);
        console.log("- Registrar:", config.networkConfig.registrar);
        console.log("- Registry:", config.networkConfig.registry);
        console.log("- Uniswap Router:", config.networkConfig.uniswapRouter);
        console.log("- WETH:", config.networkConfig.weth);
        console.log("- Max Committee Members:", config.networkConfig.maxCommitteeMembers);
        console.log("");

        // Deploy Factory
        console.log("Deploying Factory...");
        factory = new Factory(
            config.networkConfig.pyUsd,
            config.networkConfig.entropy,
            config.networkConfig.link,
            config.networkConfig.registrar,
            config.networkConfig.registry,
            config.networkConfig.weth,
            config.networkConfig.maxCommitteeMembers,
            address(new CommitteeDeployer())
        );

        console.log("\n===========================================");
        console.log("Deployment Successful!");
        console.log("===========================================");
        console.log("Factory deployed at:", address(factory));
        console.log("Factory owner:", factory.owner());
        console.log("Max committee members:", factory.maxCommitteeMembers());
        console.log("===========================================\n");

        // Save deployment
        saveDeployment("Factory", address(factory));

        // Additional verification info
        if (!isLocalTestnet()) {
            console.log("\nVerify with:");
            console.log("forge verify-contract", vm.toString(address(factory)));
            console.log("  --chain-id", vm.toString(config.chainId));
            console.log("  --constructor-args $(cast abi-encode");
            console.log("    \"constructor(address,address,address,address,address,address,address,uint256)\"");
            console.log("   ", config.networkConfig.pyUsd);
            console.log("   ", config.networkConfig.entropy);
            console.log("   ", config.networkConfig.link);
            console.log("   ", config.networkConfig.registrar);
            console.log("   ", config.networkConfig.registry);
            console.log("   ", config.networkConfig.uniswapRouter);
            console.log("   ", config.networkConfig.weth);
            console.log("   ", config.networkConfig.maxCommitteeMembers, ")");
            console.log("  src/Factory.sol:Factory");
            console.log("  --etherscan-api-key $ARBISCAN_API_KEY\n");
        }
    }
}
