// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Committee} from "./Committee.sol";
import {ICommittee} from "./Interface/ICommittee.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Committee Factory Contract
 * @author 0xusmanf
 * @notice Deploys and tracks `Committee` contracts for multi-sig owners.
 * @dev Each deployed committee has independent Chainlink Automation upkeep
 */
contract Factory is Ownable {
    error Factory__CommitteeAlreadyActive(address _committee);
    error Factory__MaxCommitteeMembersExceeded();

    address public immutable i_PyUsd;
    address public immutable i_entropy;
    address public immutable i_link;
    address public immutable i_registrar;
    address public immutable i_registry;
    address public immutable i_uniswapRouter;
    address public immutable i_weth;
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
     * @notice Initializes the Factory with all required addresses
     * @param _pyUsd Address of the PyUSD token contract
     * @param _entropy Address of the Pyth Entropy randomness provider
     * @param _link Address of the LINK token
     * @param _registrar Address of the Chainlink Automation Registrar
     * @param _registry Address of the Chainlink Automation Registry
     * @param _uniswapRouter Address of Uniswap V2 Router
     * @param _weth Address of WETH token
     * @param _maxCommitteeMembers The initial maximum number of committee members allowed
     */
    constructor(
        address _pyUsd,
        address _entropy,
        address _link,
        address _registrar,
        address _registry,
        address _uniswapRouter,
        address _weth,
        uint256 _maxCommitteeMembers
    ) Ownable(msg.sender) {
        i_PyUsd = _pyUsd;
        i_entropy = _entropy;
        i_link = _link;
        i_registrar = _registrar;
        i_registry = _registry;
        i_uniswapRouter = _uniswapRouter;
        i_weth = _weth;
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
        address[] memory _members,
        address _multiSigAccount
    ) external returns (address) {
        if (_members.length > maxCommitteeMembers) {
            revert Factory__MaxCommitteeMembersExceeded();
        }
        uint256 length = multiSigToCommittees[_multiSigAccount].length;
        if (length > 0) {
            address lastCommittee = multiSigToCommittees[_multiSigAccount][length - 1];
            if (!ICommittee(lastCommittee).s_hasEnded()) {
                revert Factory__CommitteeAlreadyActive(lastCommittee);
            }
        }
        Committee.CommitteeConfig memory committeeConfig = Committee.CommitteeConfig({
            contributionAmount: _contributionAmount,
            collectionInterval: _collectionInterval,
            distributionInterval: _distributionInterval,
            members: _members
        });
        Committee.ExternalContracts memory externalContracts = Committee.ExternalContracts({
            pyUsd: i_PyUsd,
            entropy: i_entropy,
            link: i_link,
            registrar: i_registrar,
            registry: i_registry,
            uniswapRouter: i_uniswapRouter,
            weth: i_weth
        });
        address newCommittee = address(new Committee(committeeConfig, externalContracts, _multiSigAccount));
        multiSigToCommittees[_multiSigAccount].push(newCommittee);
        emit CommitteeCreated(_multiSigAccount, newCommittee);
        return newCommittee;
    }

    /**
     * @notice Updates the maximum allowed committee members
     * @param _maxCommitteeMembers New maximum member count
     */
    function updateMaxCommitteeMembers(uint256 _maxCommitteeMembers) external onlyOwner {
        maxCommitteeMembers = _maxCommitteeMembers;
        emit MaxCommitteeMembersUpdated(_maxCommitteeMembers);
    }

    /**
     * @notice Returns all committees for a given multi-sig account
     * @param _multiSigAccount The multi-sig address to query
     * @return Array of committee addresses
     */
    function getCommittees(address _multiSigAccount) external view returns (address[] memory) {
        return multiSigToCommittees[_multiSigAccount];
    }

    /**
     * @notice Returns the most recent committee for a multi-sig account
     * @param _multiSigAccount The multi-sig address to query
     * @return Latest committee address (or zero address if none)
     */
    function getLatestCommittee(address _multiSigAccount) external view returns (address) {
        uint256 length = multiSigToCommittees[_multiSigAccount].length;
        if (length == 0) {
            return address(0);
        }
        return multiSigToCommittees[_multiSigAccount][length - 1];
    }

    /**
     * @notice Returns the total number of committees created for a multi-sig
     * @param _multiSigAccount The multi-sig address to query
     * @return Total count of committees
     */
    function getCommitteeCount(address _multiSigAccount) external view returns (uint256) {
        return multiSigToCommittees[_multiSigAccount].length;
    }
}
