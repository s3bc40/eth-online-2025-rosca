// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IPyUsd} from "./Interface/IPyUsd.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IEntropyV2} from "@pythnetwork/entropy-sdk-solidity/IEntropyV2.sol";
import {IEntropyConsumer} from "@pythnetwork/entropy-sdk-solidity/IEntropyConsumer.sol";
import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";

contract Committee is Ownable, AutomationCompatibleInterface, IEntropyConsumer {
    //--------- Errors ---------//
    error Committee__CycleOver();
    error Committee__TransferFailed();
    error Committee__UpkeepNotNeeded();
    error Committee__AlreadyWithdrawn();
    error Committee__SenderIsNotMember();
    error Committee__NothingToWithdraw();
    error Committee__WrongContributionAmount();
    error Committee__WaitForNextCycleToStart();

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
    mapping(address => bool) public s_isMember;
    mapping(address => uint256) public s_totalContributionPerMember;
    mapping(address => uint256) public s_cycleContributionPerMember;
    mapping(address => uint256) public s_cycleDistributionPerMember;
    mapping(address => bool) public s_hasWithdrawn;

    //--------- Events ---------//
    event ContributionDeposited(address indexed member, uint256 contributionAmount);
    event ShareWithdrawn(address indexed member, uint256 shareAmount);

    constructor(
        uint256 _contributionAmount,
        uint256 _collectionInterval,
        uint256 _distributionInterval,
        uint256 _totalCycles,
        address[] memory _members,
        address _pyUsd,
        address _entropy,
        address _multiSigAccount
    ) Ownable(_multiSigAccount) {
        //--------- Immutables Assignments ---------//
        i_contributionAmount = _contributionAmount;
        i_collectionInterval = _collectionInterval;
        i_distributionInterval = _distributionInterval;
        i_totalCycles = _totalCycles;

        //--------- State Variable Assignments ---------//
        pyUsd = IPyUsd(_pyUsd);
        i_entropy = IEntropyV2(_entropy);
        s_members = _members;
        s_remainingWinners = _members;
        uint256 i;
        for (; i < _members.length;) {
            s_isMember[s_members[i]] = true;
            unchecked {
                ++i;
            }
        }
    }

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
            revert Committee__TransferFailed();
        }
    }

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
            revert Committee__TransferFailed();
        }
    }

    function _isDistributionTime() private view returns (bool) {
        return block.timestamp >= s_lastDistributionTime + i_collectionInterval;
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
        upkeepNeeded = (isDistributionTime && hasEveryoneContributed && cycleHasNotEnded);
        return (upkeepNeeded, "0x0");
    }

    function performUpkeep(bytes calldata /* performData */ ) external override {
        (bool upkeepNeeded,) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Committee__UpkeepNotNeeded();
        }

        uint128 requestFee = i_entropy.getFeeV2();
        if (address(this).balance < requestFee) revert("not enough fees");
        uint64 sequenceNumber = i_entropy.requestV2{value: requestFee}();
    }

    function entropyCallback(uint64 sequenceNumber, address _providerAddress, bytes32 randomNumber) internal override {
        s_lastDistributionTime += i_collectionInterval;
        s_currentCycle += 1;
        s_cycleContribution = 0;
        uint256 totalMembers = s_members.length;
        uint256 totalRemainingWinners = s_remainingWinners.length;
        uint256 i;
        for (; i < totalMembers;) {
            s_cycleDistributionPerMember[s_members[i]] = 0;
            unchecked {
                ++i;
            }
        }

        if (totalMembers > 1) {
            address winner;
            uint256 index = uint256(randomNumber) % totalRemainingWinners;
            winner = s_remainingWinners[index];
            if (!(index == totalRemainingWinners - 1)) {
                s_remainingWinners[index] = s_remainingWinners[totalRemainingWinners - 1];
                s_remainingWinners.pop();
            }
            s_cycleDistributionPerMember[winner] = s_cycleContribution;
        } else {
            s_cycleDistributionPerMember[s_members[0]] = s_cycleContribution;
        }
    }

    function getEntropy() internal view override returns (address) {
        return address(i_entropy);
    }
}
