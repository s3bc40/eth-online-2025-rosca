// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Committee} from "./Committee.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Committee Factory Contract
 * @author 0xusmanf
 * @notice Deploys and tracks `Committee` contracts for multi-sig owners.
 */
contract Factory is Ownable {
    error Factory__CommitteeAlreadyActive(address _committee);

    address public immutable i_PyUsd;
    address public immutable i_entropy;
    uint256 public maxCommitteeMembers;
    mapping(address => address[]) public multiSigToCommittees;

    /**
     * @notice Emitted when a new committee is successfully created.
     * @param multiSigAccount The multi-sig address that owns the committee.
     * @param committee The address of the newly created committee.
     */
    event CommitteeCreated(address indexed multiSigAccount, address indexed committee);

    /**
     * @notice Emitted when the maximum allowed number of committee members is updated.
     * @param newMax The new maximum number of members allowed per committee.
     */
    event MaxCommitteeMembersUpdated(uint256 newMax);

    /**
     * @notice Initializes the Factory with PyUSD, Pyth Entropy, and a max member limit.
     * @param _pyUsd Address of the PyUSD token contract.
     * @param _entropy Address of the Pyth Entropy randomness provider.
     * @param _maxCommitteeMembers The initial maximum number of committee members allowed.
     */
    constructor(address _pyUsd, address _entropy, uint256 _maxCommitteeMembers) Ownable(msg.sender) {
        i_PyUsd = _pyUsd;
        i_entropy = _entropy;
        maxCommitteeMembers = _maxCommitteeMembers;
    }

    /**
     * @notice Deploys a new `Committee` contract for a given multi-sig account.
     * @dev Ensures that the multi-sig account does not already have an active committee.
     * @param _contributionAmount Fixed contribution amount per member per cycle.
     * @param _collectionInterval Time interval (in seconds) for collecting contributions.
     * @param _distributionInterval Time interval (in seconds) between distributions.
     * @param _members List of member addresses participating in the committee.
     * @param _multiSigAccount Multi-sig address that will own the new committee.
     * @return newCommittee Address of the newly created `Committee` contract.
     *
     * Requirements:
     * - The last deployed committee for `_multiSigAccount` must have ended.
     * - The `_members` array must not exceed `maxCommitteeMembers`.
     */
    function createCommittee(
        uint256 _contributionAmount,
        uint256 _collectionInterval,
        uint256 _distributionInterval,
        /*uint256 _totalCycles,*/
        address[] memory _members,
        address _multiSigAccount
    ) external returns (address) {
        uint256 length = multiSigToCommittees[_multiSigAccount].length;
        if (length > 0) {
            address lastCommittee = multiSigToCommittees[_multiSigAccount][length - 1];
            if (!Committee(lastCommittee).s_hasEnded()) {
                revert Factory__CommitteeAlreadyActive(lastCommittee);
            }
        }
        address newCommittee = address(
            new Committee(
                _contributionAmount,
                _collectionInterval,
                _distributionInterval,
                _members,
                i_PyUsd,
                i_entropy,
                _multiSigAccount
            )
        );
        multiSigToCommittees[_multiSigAccount].push(newCommittee);
        emit CommitteeCreated(_multiSigAccount, newCommittee);
        return newCommittee;
    }

    function updateMaxCommitteeMembers(uint256 _maxCommitteeMembers) external onlyOwner {
        maxCommitteeMembers = _maxCommitteeMembers;
        emit MaxCommitteeMembersUpdated(_maxCommitteeMembers);
    }
}
