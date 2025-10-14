// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IPyUsd} from "./Interface/IPyUsd.sol";

contract Committee is Ownable {
    //--------- Errors ---------
    error Committee__TransferFailed();
    error Committee__SenderIsNotMember();
    error Committee__WrongContributionAmount();
    error Committee__CycleOver();
    error Committee__WaitForNextCycleToStart();
    error Committee__AlreadyWithdrawn();
    error Committee__NothingToWithdraw();

    //--------- Immutables ---------
    uint256 public immutable i_contributionAmount;
    uint256 public immutable i_collectionInterval;
    uint256 public immutable i_distributionInterval;
    uint256 public immutable i_totalCycles;
    IPyUsd public immutable pyUsd;

    //--------- State Variables ---------
    uint256 public s_currentCycle;
    uint256 public s_lastDistributionTime;
    address[] public s_members;
    mapping(address => bool) public s_isMember;
    mapping(address => uint256) public s_totalContribution;
    mapping(address => uint256) public s_cycleContribution;
    mapping(address => uint256) public s_cycleDistribution;
    mapping(address => bool) public s_hasWithdrawn;

    //--------- Events ---------
    event ContributionDeposited(address indexed member, uint256 contributionAmount);
    event ShareWithdrawn(address indexed member, uint256 shareAmount);

    constructor(
        uint256 _contributionAmount,
        uint256 _collectionInterval,
        uint256 _distributionInterval,
        uint256 _totalCycles,
        address[] memory _members,
        address _pyUsd,
        address _multiSigAccount
    ) Ownable(_multiSigAccount) {
        //--------- Immutables Assignments ---------
        i_contributionAmount = _contributionAmount;
        i_collectionInterval = _collectionInterval;
        i_distributionInterval = _distributionInterval;
        i_totalCycles = _totalCycles;

        //--------- State Variable Assignments ---------
        pyUsd = IPyUsd(_pyUsd);
        s_members = _members;
        uint256 i;
        for (; i < _members.length;) {
            s_isMember[s_members[i]] = true;
            unchecked {
                ++i;
            }
        }
    }

    function depositContribution(uint256 _contributionAmount) external {
        //--------- Checks ---------
        if (!s_isMember[msg.sender]) {
            revert Committee__SenderIsNotMember();
        }
        if (_contributionAmount != i_contributionAmount) {
            revert Committee__WrongContributionAmount();
        }
        if (s_currentCycle >= i_totalCycles) {
            revert Committee__CycleOver();
        }
        if (s_cycleContribution[msg.sender] != 0) {
            revert Committee__WaitForNextCycleToStart();
        }

        //--------- Effects ---------
        s_totalContribution[msg.sender] += i_contributionAmount;
        s_cycleContribution[msg.sender] = i_contributionAmount;
        emit ContributionDeposited(msg.sender, i_contributionAmount);

        //--------- Interaction ---------
        bool success = pyUsd.transferFrom(msg.sender, address(this), i_contributionAmount);
        if (!success) {
            revert Committee__TransferFailed();
        }
    }

    function withdrawYourShare() external {
        uint256 share = s_cycleDistribution[msg.sender];
        //--------- Checks ---------
        if (!s_isMember[msg.sender]) {
            revert Committee__SenderIsNotMember();
        }
        if (s_hasWithdrawn[msg.sender]) {
            revert Committee__AlreadyWithdrawn();
        }
        if (share == 0) {
            revert Committee__NothingToWithdraw();
        }

        //--------- Effects ---------
        s_hasWithdrawn[msg.sender] = true;
        emit ShareWithdrawn(msg.sender, share);

        //--------- Interaction ---------
        bool success = pyUsd.transfer(msg.sender, share);
        if (!success) {
            revert Committee__TransferFailed();
        }
    }

    function _isDistributionTime() private view returns (bool) {
        return block.timestamp >= s_lastDistributionTime + i_collectionInterval;
    }
}
