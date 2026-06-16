// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IUniswapV2Router02 {
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
}

interface IPool {
    function supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;
}

contract DeFiInteractions is Script {
    address constant UNISWAP_V2_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address constant AAVE_POOL = 0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2;
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    function run() public {
        vm.startBroadcast();

        console.log("Swapping 1 ETH for USDC on Uniswap...");
        
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = USDC;
        
        uint256 deadline = block.timestamp + 300;

        IUniswapV2Router02(UNISWAP_V2_ROUTER).swapExactETHForTokens{value: 1 ether}(
            0,
            path,
            msg.sender,
            deadline
        );

        uint256 usdcBalance = IERC20(USDC).balanceOf(msg.sender);
        console.log("Received USDC:", usdcBalance);

        console.log("Approving and Supplying USDC to Aave...");
        
        IERC20(USDC).approve(AAVE_POOL, usdcBalance);
        IPool(AAVE_POOL).supply(USDC, usdcBalance, msg.sender, 0);

        console.log("Successfully supplied USDC to Aave!");

        vm.stopBroadcast();
    }
}
