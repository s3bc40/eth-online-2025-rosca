// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IPyUsd} from "./Interface/IPyUsd.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IEntropyV2} from "@pythnetwork/entropy-sdk-solidity/IEntropyV2.sol";
import {IEntropyConsumer} from "@pythnetwork/entropy-sdk-solidity/IEntropyConsumer.sol";
import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";

/**
 * @title Committee Contract
 * @author 0xusmanf
 * @notice Implements a rotating savings and credit association (ROSCA) mechanism and chooses a random winner
 * every `distributionInterval`.
 * @dev Integrates Chainlink Automation for time-based upkeep and Pyth Entropy for verifiable randomness.
 */
contract Committee is Ownable, AutomationCompatibleInterface, IEntropyConsumer {
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

    //--------- Immutables ---------//
    IPyUsd public immutable pyUsd;
    IEntropyV2 public immutable i_entropy;
    uint256 public immutable i_totalCycles;
    uint256 public immutable i_contributionAmount;
    uint256 public immutable i_collectionInterval;
    uint256 public immutable i_distributionInterval;

    //--------- State Variables ---------//
    uint256 public s_currentCycle;
    uint256 public s_lastDistributionTime;
    uint256 public s_totalContribution;
    uint256 public s_cycleContribution;
    address[] public s_members;
    address[] public s_remainingWinners;
    bool public s_hasEnded;
    mapping(address => bool) public s_isMember;
    mapping(address => uint256) public s_totalContributionPerMember;
    mapping(address => uint256) public s_cycleContributionPerMember;
    mapping(address => uint256) public s_cycleDistributionPerMember;
    mapping(address => bool) public s_hasWithdrawn;

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

    /**
     * @notice Initializes the committee parameters and member list.
     * @param _contributionAmount Fixed contribution amount per member per cycle.
     * @param _collectionInterval Duration between contribution collections (seconds).
     * @param _distributionInterval Duration between distributions (seconds).
     * @param _members List of member addresses.
     * @param _pyUsd Address of the PyUSD token.
     * @param _entropy Address of the Pyth Entropy contract.
     * @param _multiSigAccount Address of the multisig owner.
     */
    constructor(
        uint256 _contributionAmount,
        uint256 _collectionInterval,
        uint256 _distributionInterval,
        address[] memory _members,
        address _pyUsd,
        address _entropy,
        address _multiSigAccount
    ) Ownable(_multiSigAccount) {
        //--------- Immutables Assignments ---------//
        i_contributionAmount = _contributionAmount;
        i_collectionInterval = _collectionInterval;
        i_distributionInterval = _distributionInterval;
        i_totalCycles = _members.length;

        //--------- State Variable Assignments ---------//
        s_lastDistributionTime = block.timestamp;
        pyUsd = IPyUsd(_pyUsd);
        i_entropy = IEntropyV2(_entropy);
        s_members = _members;
        s_remainingWinners = _members;
        uint256 i;
        for (; i < _members.length;) {
            if (s_isMember[s_members[i]] == true) {
                revert Committee__DuplicateMembersNotAllowed();
            }
            s_isMember[s_members[i]] = true;
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Allows a member to deposit their contribution for the current cycle.
     * @param _contributionAmount The amount being contributed (must match `i_contributionAmount`).
     * @dev Transfers tokens from the sender to this contract.
     */
    function depositContribution(uint256 _contributionAmount) external {
        //--------- Checks ---------//
        if (!s_isMember[msg.sender]) {
            revert Committee__SenderIsNotMember();
        }
        if (_contributionAmount != i_contributionAmount) {
            revert Committee__WrongContributionAmount();
        }
        if (s_currentCycle >= i_totalCycles) {
            revert Committee__CycleOver();
        }
        if (s_cycleContributionPerMember[msg.sender] != 0) {
            revert Committee__WaitForNextCycleToStart();
        }

        //--------- Effects ---------//
        s_totalContributionPerMember[msg.sender] += i_contributionAmount;
        s_cycleContributionPerMember[msg.sender] = i_contributionAmount;
        s_totalContribution += i_contributionAmount;
        s_cycleContribution += i_contributionAmount;
        emit ContributionDeposited(msg.sender, i_contributionAmount);

        //--------- Interaction ---------//
        bool success = pyUsd.transferFrom(msg.sender, address(this), i_contributionAmount);
        if (!success) {
            revert Committee__DepositFailed();
        }
    }

    /**
     * @notice Allows a winning member to withdraw their distributed share.
     * @dev Prevents multiple withdrawals per cycle.
     */
    function withdrawYourShare() external {
        uint256 share = s_cycleDistributionPerMember[msg.sender];
        //--------- Checks ---------//
        if (!s_isMember[msg.sender]) {
            revert Committee__SenderIsNotMember();
        }
        if (s_hasWithdrawn[msg.sender]) {
            revert Committee__AlreadyWithdrawn();
        }
        if (share == 0) {
            revert Committee__NothingToWithdraw();
        }

        //--------- Effects ---------//
        s_hasWithdrawn[msg.sender] = true;
        emit ShareWithdrawn(msg.sender, share);

        //--------- Interaction ---------//
        bool success = pyUsd.transfer(msg.sender, share);
        if (!success) {
            revert Committee__WithdrawFailed();
        }
    }

    /**
     * @notice Internal helper that checks if the distribution interval has passed.
     * @return True if its time to select a winner and new distribution cycle to start.
     */
    function _isDistributionTime() private view returns (bool) {
        return block.timestamp >= s_lastDistributionTime + i_distributionInterval;
    }

    function checkUpkeep(bytes memory /* checkData */ )
        public
        view
        override
        returns (bool upkeepNeeded, bytes memory /* performData */ )
    {
        bool isDistributionTime = _isDistributionTime();
        bool hasEveryoneContributed = s_cycleContribution == (s_members.length * i_contributionAmount);
        bool cycleHasNotEnded = s_currentCycle < i_totalCycles;
        upkeepNeeded = (isDistributionTime && hasEveryoneContributed && cycleHasNotEnded && !s_hasEnded);
        return (upkeepNeeded, "0x0");
    }

    function performUpkeep(bytes calldata /* performData */ ) external override {
        (bool upkeepNeeded,) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Committee__UpkeepNotNeeded();
        }

        if (s_remainingWinners.length > 1) {
            uint128 requestFee = i_entropy.getFeeV2();
            if (address(this).balance < requestFee) revert("not enough fees");
            uint64 sequenceNumber = i_entropy.requestV2{value: requestFee}();
        } else {
            s_lastDistributionTime += i_collectionInterval;
            s_currentCycle += 1;
            uint256 totalMembers = s_members.length;
            uint256 i;
            for (; i < totalMembers;) {
                s_cycleContributionPerMember[s_members[i]] = 0;
                unchecked {
                    ++i;
                }
            }
            s_cycleDistributionPerMember[s_members[0]] = s_cycleContribution;
            s_remainingWinners.pop();
            s_cycleContribution = 0;
            emit WinnerPicked(s_members[0]);
            s_hasEnded = true;
        }
    }

    function entropyCallback(uint64 sequenceNumber, address _providerAddress, bytes32 randomNumber) internal override {
        s_lastDistributionTime += i_collectionInterval;
        s_currentCycle += 1;
        uint256 totalMembers = s_members.length;
        uint256 totalRemainingWinners = s_remainingWinners.length;
        uint256 i;
        for (; i < totalMembers;) {
            s_cycleContributionPerMember[s_members[i]] = 0;
            unchecked {
                ++i;
            }
        }

        address winner;
        uint256 index = uint256(randomNumber) % totalRemainingWinners;
        winner = s_remainingWinners[index];
        if (!(index == totalRemainingWinners - 1)) {
            s_remainingWinners[index] = s_remainingWinners[totalRemainingWinners - 1];
        }
        s_remainingWinners.pop();
        s_cycleDistributionPerMember[winner] = s_cycleContribution;
        emit WinnerPicked(winner);
        s_cycleContribution = 0;
    }

    function getEntropy() internal view override returns (address) {
        return address(i_entropy);
    }

    /**
     * @notice Allows anyone to send ETH to fund randomness fees.
     */
    function fundEntropy() external payable {}

    /**
     * @notice Withdraws all ETH held by the contract to the owner.
     */
    function withdrawEth() external onlyOwner {
        (bool success,) = payable(owner()).call{value: address(this).balance}("");
        if (!success) {
            revert Committee__EthTransferFailed();
        }
    }
}
