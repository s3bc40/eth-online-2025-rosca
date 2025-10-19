// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/**
 * @title ICommittee
 * @notice Interface for the Committee contract implementing a rotating savings and credit association (ROSCA)
 */
interface ICommittee {
    //--------- Errors ---------//
    error Committee__CycleOver();
    error Committee__DepositFailed();
    error Committee__WithdrawFailed();
    error Committee__UpkeepNotNeeded();
    error Committee__AlreadyWithdrawn();
    error Committee__NothingToWithdraw();
    error Committee__EthTransferFailed();
    error Committee__SenderIsNotMember();
    error Committee__WaitForNextCycleToStart();
    error Committee__WrongContributionAmount();
    error Committee__DuplicateMembersNotAllowed();
    error Committee__InsufficientFunding();
    error Committee__LinkTransferFailed();
    error Committee__UpkeepNotRegistered();
    error Committee__SwapFailed();
    error Committee__InvalidPercentage();

    /**
     * @notice Struct to hold committee configuration parameters
     */
    struct CommitteeConfig {
        uint256 contributionAmount;
        uint256 collectionInterval;
        uint256 distributionInterval;
        address[] members;
    }

    /**
     * @notice Struct to hold external contract addresses
     */
    struct ExternalContracts {
        address pyUsd;
        address entropy;
        address link;
        address registrar;
        address registry;
        address uniswapRouter;
        address weth;
    }

    //--------- Events ---------//
    /**
     * @notice Emitted when a member successfully contributes.
     * @param member Address of the contributing member.
     * @param contributionAmount The contributed amount.
     */
    event ContributionDeposited(address indexed member, uint256 contributionAmount);

    /**
     * @notice Emitted when a member withdraws their winnings.
     * @param member Address of the withdrawing member.
     * @param shareAmount The withdrawn amount.
     */
    event ShareWithdrawn(address indexed member, uint256 shareAmount);

    /**
     * @notice Emitted when a winner is selected for a cycle.
     * @param winner Address of the winning member.
     */
    event WinnerPicked(address indexed winner);

    event FundsDeposited(address indexed funder, uint256 totalAmount, uint256 entropyAmount, uint256 linkAmount);

    event UpkeepFunded(uint256 indexed upkeepId, uint256 linkAmount);

    event UpkeepRegistered(uint256 indexed s_upkeepId);

    //--------- External Functions ---------//

    /**
     * @notice Allows anyone to deposit ETH to fund both Pyth Entropy and Chainlink Automation
     * @param _entropyFeePercentage Percentage (0-100) of ETH to keep for Entropy fees
     */
    function fundAutomation(uint256 _entropyFeePercentage) external payable;

    /**
     * @notice Alternative funding method - deposit LINK directly
     * @param _linkAmount Amount of LINK to deposit
     */
    function fundAutomationWithLink(uint96 _linkAmount) external;

    /**
     * @notice Allows a member to deposit their contribution for the current cycle.
     * @param _contributionAmount The amount being contributed (must match `i_contributionAmount`).
     */
    function depositContribution(uint256 _contributionAmount) external;

    /**
     * @notice Allows a winning member to withdraw their distributed share.
     */
    function withdrawYourShare() external;

    /**
     * @notice Chainlink Automation check function
     * @return upkeepNeeded True if upkeep is needed
     * @return performData Data to pass to performUpkeep
     */
    function checkUpkeep(bytes memory checkData) external view returns (bool upkeepNeeded, bytes memory performData);

    /**
     * @notice Chainlink Automation perform function
     * @param performData Data from checkUpkeep
     */
    function performUpkeep(bytes calldata performData) external;

    /**
     * @notice Allows anyone to send ETH to fund randomness fees.
     */
    function fundEntropy() external payable;

    /**
     * @notice Returns current upkeep balance
     * @return balance Current LINK balance in upkeep
     */
    function getUpkeepBalance() external view returns (uint96 balance);

    /**
     * @notice Withdraws excess LINK to owner
     */
    function withdrawLink() external;

    /**
     * @notice Withdraws all ETH held by the contract to the owner.
     */
    function withdrawEth() external;

    /**
     * @notice Get upkeep ID for this committee
     * @return upkeepId The Chainlink Automation upkeep ID
     */
    function getUpkeepId() external view returns (uint256 upkeepId);

    /**
     * @notice Get expected LINK output for ETH amount
     * @param _ethAmount Amount of ETH to swap
     * @return expectedLink Expected amount of LINK tokens
     */
    function getExpectedLinkOutput(uint256 _ethAmount) external view returns (uint256 expectedLink);

    //--------- View Functions for State Variables ---------//

    function i_pyUsd() external view returns (address);

    function i_entropy() external view returns (address);

    function i_link() external view returns (address);

    function i_registrar() external view returns (address);

    function i_registry() external view returns (address);

    function i_uniswapRouter() external view returns (address);

    function i_weth() external view returns (address);

    function i_totalCycles() external view returns (uint256);

    function i_contributionAmount() external view returns (uint256);

    function i_collectionInterval() external view returns (uint256);

    function i_distributionInterval() external view returns (uint256);

    function s_currentCycle() external view returns (uint256);

    function s_lastDistributionTime() external view returns (uint256);

    function s_totalContribution() external view returns (uint256);

    function s_cycleContribution() external view returns (uint256);

    function s_upkeepId() external view returns (uint256);

    function s_members(uint256 index) external view returns (address);

    function s_remainingWinners(uint256 index) external view returns (address);

    function s_hasEnded() external view returns (bool);

    function s_isMember(address member) external view returns (bool);

    function s_totalContributionPerMember(address member) external view returns (uint256);

    function s_cycleContributionPerMember(address member) external view returns (uint256);

    function s_cycleDistributionPerMember(address member) external view returns (uint256);

    function s_hasWithdrawn(address member) external view returns (bool);
}
