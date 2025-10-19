// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IUniswapV2Router {
    function WETH() external pure returns (address);

    function swapExactETHForTokens(uint256 amountOutMin, address[] calldata path, address to, uint256 deadline)
        external
        payable
        returns (uint256[] memory amounts);
}

contract EthToLinkSwapper {
    address private constant UNISWAP_V2_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address private constant LINK = 0x514910771AF9Ca656af840dff83E8264EcF986CA;

    function swapEthForLink(uint256 amountOutMin) external payable {
        require(msg.value > 0, "Send ETH to swap");

        IUniswapV2Router router = IUniswapV2Router(UNISWAP_V2_ROUTER);

        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = LINK;

        router.swapExactETHForTokens{value: msg.value}(
            amountOutMin, // slippage protection
            path,
            msg.sender, // send LINK to user
            block.timestamp + 1200 // 20 min deadline
        );
    }
}
