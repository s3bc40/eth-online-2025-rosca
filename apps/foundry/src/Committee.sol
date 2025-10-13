// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Committee is Ownable {
    uint256 public immutable i_contributionAmount;
    uint256 public immutable i_collectionInterval;
    uint256 public immutable i_distributionInterval;
    address[] public s_members;
    IERC20 public pyUsd;
    mapping(address => bool) public s_isMember;

    constructor(
        uint256 _contributionAmount,
        uint256 _collectionInterval,
        uint256 _distributionInterval,
        address[] memory _members,
        address _multiSigAccount
    ) Ownable(_multiSigAccount) {
        i_contributionAmount = _contributionAmount;
        i_collectionInterval = _collectionInterval;
        i_distributionInterval = _distributionInterval;
        s_members = _members;

        uint256 i;
        for (; i < _members.length;) {
            s_isMember[s_members[i]] = true;
            unchecked {
                ++i;
            }
        }
    }
}
