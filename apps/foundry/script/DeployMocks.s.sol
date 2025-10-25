// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {BaseDeployScript} from "./BaseDeployScript.sol";
import {MockAutomationRegistrar, MockAutomationRegistry} from "../test/Mocks/MockAutomationRegistrarAndRegistry.sol";
import {MockERC20} from "../test/Mocks/MockERC20.sol";
import {MockWETH} from "../test/Mocks/MockWeth.sol";
import {MockEntropy} from "../test/Mocks/MockEntropy.sol";

/**
 * @title DeployMocks
 * @notice Deploys all mock contracts for local Anvil testing
 * @dev This should only be used on Anvil/local networks
 */
contract DeployMocks is BaseDeployScript {
    MockERC20 public pyUsd;
    MockERC20 public link;
    MockWETH public weth;
    MockEntropy public entropy;
    MockAutomationRegistry public registry;
    MockAutomationRegistrar public registrar;

    function run() public override broadcast {
        setUp();

        require(config.chainId == ANVIL, "Mock deployment only supported on Anvil");

        console.log("\n===========================================");
        console.log("Deploying Mock Contracts");
        console.log("===========================================\n");

        deployMocks();
        fundMocks();
        printSummary();
        saveMockDeployments();
    }

    function deployMocks() internal {
        console.log("Deploying mock contracts...\n");

        // Deploy PyUSD
        console.log("1. Deploying Mock PyUSD...");
        pyUsd = new MockERC20("PayPal USD", "PYUSD", 6);
        console.log("   PyUSD:", address(pyUsd));

        // Deploy LINK
        console.log("2. Deploying Mock LINK...");
        link = new MockERC20("ChainLink Token", "LINK", 18);
        console.log("   LINK:", address(link));

        // Deploy WETH
        console.log("3. Deploying Mock WETH...");
        weth = new MockWETH();
        console.log("   WETH:", address(weth));

        // Deploy Entropy
        console.log("4. Deploying Mock Entropy...");
        entropy = new MockEntropy();
        console.log("   Entropy:", address(entropy));

        // Deploy Automation Registry
        console.log("5. Deploying Mock Automation Registry...");
        registry = new MockAutomationRegistry();
        console.log("   Registry:", address(registry));

        // Deploy Automation Registrar
        console.log("6. Deploying Mock Automation Registrar...");
        registrar = new MockAutomationRegistrar(address(registry));
        console.log("   Registrar:", address(registrar));

        console.log("");
    }

    function fundMocks() internal {
        console.log("Funding mock contracts with test tokens...\n");

        // Mint PyUSD to deployer
        uint256 pyUsdAmount = 1_000_000 * 1e6; // 1M PyUSD
        pyUsd.mint(config.deployer, pyUsdAmount);
        console.log("Minted", pyUsdAmount / 1e6, "PyUSD to deployer");

        // Mint LINK to deployer
        uint256 linkAmount = 10_000 * 1e18; // 10K LINK
        link.mint(config.deployer, linkAmount);
        console.log("Minted", linkAmount / 1e18, "LINK to deployer");

        console.log("");
    }

    function printSummary() internal view {
        console.log("===========================================");
        console.log("Mock Deployment Summary");
        console.log("===========================================");
        console.log("Network: Anvil (Local)");
        console.log("Deployer:", config.deployer);
        console.log("");
        console.log("Deployed Contracts:");
        console.log("-------------------------------------------");
        console.log("PyUSD:", address(pyUsd));
        console.log("LINK:", address(link));
        console.log("WETH:", address(weth));
        console.log("Entropy:", address(entropy));
        console.log("Registry:", address(registry));
        console.log("Registrar:", address(registrar));
        console.log("===========================================\n");

        console.log("Environment Variables for .env:");
        console.log("-------------------------------------------");
        console.log("PYUSD_ADDRESS=", vm.toString(address(pyUsd)));
        console.log("ENTROPY_ADDRESS=", vm.toString(address(entropy)));
        console.log("LINK_ADDRESS=", vm.toString(address(link)));
        console.log("REGISTRAR_ADDRESS=", vm.toString(address(registrar)));
        console.log("REGISTRY_ADDRESS=", vm.toString(address(registry)));
        console.log("WETH_ADDRESS=", vm.toString(address(weth)));
        console.log("===========================================\n");
    }

    function saveMockDeployments() internal {
        saveDeployment("MockPyUSD", address(pyUsd));
        saveDeployment("MockLINK", address(link));
        saveDeployment("MockWETH", address(weth));
        saveDeployment("MockEntropy", address(entropy));
        saveDeployment("MockRegistry", address(registry));
        saveDeployment("MockRegistrar", address(registrar));
    }
}
