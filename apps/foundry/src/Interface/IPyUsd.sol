// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IPyUsd {
    function allowance(address owner, address spender) external view returns (uint256);
    function balanceOf(address addr) external view returns (uint256);
    function decimals() external view returns (uint8);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function totalSupply() external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function decreaseApproval(address spender, uint256 subtractedValue) external returns (bool);
    function increaseApproval(address spender, uint256 addedValue) external returns (bool);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function transferFromBatch(address[] calldata from, address[] calldata to, uint256[] calldata value)
        external
        returns (bool);
    function transferWithAuthorization(
        address from,
        address to,
        uint256 value,
        uint256 validAfter,
        uint256 validBefore,
        bytes32 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
    function transferWithAuthorizationBatch(
        address[] calldata from,
        address[] calldata to,
        uint256[] calldata value,
        uint256[] calldata validAfter,
        uint256[] calldata validBefore,
        bytes32[] calldata nonce,
        uint8[] calldata v,
        bytes32[] calldata r,
        bytes32[] calldata s
    ) external;
}
