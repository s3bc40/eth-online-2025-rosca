// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IAutomationRegistrar, IAutomationRegistry} from "../../src/Interface/IAutomationRegistrarAndRegistry.sol";

// ===========================================
// Mock Chainlink Automation Registrar
// ===========================================

contract MockAutomationRegistrar is IAutomationRegistrar {
    uint256 private upkeepIdCounter = 1;
    address public immutable registry;

    event UpkeepRegistered(uint256 indexed upkeepId, address indexed upkeepContract);

    constructor(address _registry) {
        registry = _registry;
    }

    function registerUpkeep(RegistrationParams calldata params) external returns (uint256) {
        require(params.amount >= 5 ether, "Insufficient LINK");

        uint256 upkeepId = upkeepIdCounter++;

        // Transfer LINK to registry (mock)
        // In real implementation, this would transfer from msg.sender

        emit UpkeepRegistered(upkeepId, params.upkeepContract);

        // Register with registry
        MockAutomationRegistry(registry).registerUpkeep(
            upkeepId, params.upkeepContract, params.adminAddress, params.amount
        );

        return upkeepId;
    }
}

// ===========================================
// Mock Chainlink Automation Registry
// ===========================================

contract MockAutomationRegistry is IAutomationRegistry {
    mapping(uint256 => UpkeepInfo) public upkeeps;

    event UpkeepFunded(uint256 indexed upkeepId, uint96 amount);
    event UpkeepPerformed(uint256 indexed upkeepId);

    function registerUpkeep(uint256 id, address target, address admin, uint96 amount) external {
        upkeeps[id] = UpkeepInfo({
            target: target,
            executeGas: 500000,
            checkData: "",
            balance: amount,
            admin: admin,
            maxValidBlocknumber: type(uint64).max,
            lastPerformBlockNumber: 0,
            amountSpent: 0,
            paused: false,
            offchainConfig: ""
        });
    }

    function getUpkeep(uint256 id) external view returns (UpkeepInfo memory) {
        return upkeeps[id];
    }

    function addFunds(uint256 id, uint96 amount) external {
        require(upkeeps[id].target != address(0), "Upkeep does not exist");
        upkeeps[id].balance += amount;
        emit UpkeepFunded(id, amount);
    }

    // Simulate upkeep performance
    function performUpkeep(uint256 id, bytes calldata performData) external {
        require(upkeeps[id].target != address(0), "Upkeep does not exist");
        require(!upkeeps[id].paused, "Upkeep is paused");

        (bool success,) = upkeeps[id].target.call(abi.encodeWithSignature("performUpkeep(bytes)", performData));
        require(success, "performUpkeep failed");

        emit UpkeepPerformed(id);
    }
}
