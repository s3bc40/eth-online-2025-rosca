// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

interface IAutomationRegistrar {
    struct RegistrationParams {
        string name;
        bytes encryptedEmail;
        address upkeepContract;
        uint32 gasLimit;
        address adminAddress;
        uint8 triggerType;
        bytes checkData;
        bytes triggerConfig;
        bytes offchainConfig;
        uint96 amount;
    }

    function registerUpkeep(RegistrationParams calldata requestParams) external returns (uint256);
}

interface IAutomationRegistry {
    function addFunds(uint256 id, uint96 amount) external;

    struct UpkeepInfo {
        address target;
        uint32 executeGas;
        bytes checkData;
        uint96 balance;
        address admin;
        uint64 maxValidBlocknumber;
        uint32 lastPerformBlockNumber;
        uint96 amountSpent;
        bool paused;
        bytes offchainConfig;
    }

    function getUpkeep(uint256 id) external view returns (UpkeepInfo memory);
}
