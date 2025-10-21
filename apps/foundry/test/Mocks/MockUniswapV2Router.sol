// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IUniswapV2Router} from "../../src/Interface/IUniswapV2Router.sol";
import {MockERC20} from "./MockERC20.sol";

// ===========================================
// Mock Uniswap V2 Router
// ===========================================

contract MockUniswapV2Router is IUniswapV2Router {
    // Simplified mock: 1 ETH = 1000 LINK
    uint256 constant ETH_TO_LINK_RATE = 1000;

    function swapExactETHForTokens(uint256 amountOutMin, address[] calldata path, address to, uint256 deadline)
        external
        payable
        returns (uint256[] memory amounts)
    {
        require(block.timestamp <= deadline, "Deadline expired");
        require(path.length == 2, "Invalid path");
        require(msg.value > 0, "Insufficient input");

        amounts = new uint256[](2);
        amounts[0] = msg.value;
        amounts[1] = (msg.value * ETH_TO_LINK_RATE) / 1 ether;

        require(amounts[1] >= amountOutMin, "Insufficient output");

        // Mint LINK tokens to recipient
        MockERC20(path[1]).mint(to, amounts[1]);

        return amounts;
    }

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        pure
        returns (uint256[] memory amounts)
    {
        require(path.length == 2, "Invalid path");

        amounts = new uint256[](2);
        amounts[0] = amountIn;
        amounts[1] = (amountIn * ETH_TO_LINK_RATE) / 1 ether;

        return amounts;
    }
}
