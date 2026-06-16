// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DEX {
    error DexAlreadyInitialized();
    error TokenTransferFailed();
    error InsufficientLiquidity();
    error TransferFailed();

    IERC20 public immutable token;
    uint256 public totalLiquidity;
    mapping(address => uint256) public liquidity;

    event EthToTokenSwap(address swapper, string tradeType, uint256 ethInput, uint256 tokenOutput);
    event TokenToEthSwap(address swapper, string tradeType, uint256 tokensInput, uint256 ethOutput);
    event LiquidityProvided(address liquidityProvider, uint256 liquidityMinted, uint256 ethIn, uint256 tokensIn);
    event LiquidityRemoved(address liquidityProvider, uint256 liquidityWithdrawn, uint256 ethOut, uint256 tokensOut);

    constructor(address tokenAddr) {
        token = IERC20(tokenAddr);
    }

    function init(uint256 tokens) public payable returns (uint256 initialLiquidity) {
        if (totalLiquidity != 0) revert DexAlreadyInitialized();

        initialLiquidity = address(this).balance;
        totalLiquidity = initialLiquidity;
        liquidity[msg.sender] = initialLiquidity;

        bool success = token.transferFrom(msg.sender, address(this), tokens);
        if (!success) revert TokenTransferFailed();

        return initialLiquidity;
    }

    function price(uint256 xInput, uint256 xReserves, uint256 yReserves) public pure returns (uint256 yOutput) {
        uint256 xInputWithFee = xInput * 997;
        uint256 numerator = xInputWithFee * yReserves;
        uint256 denominator = (xReserves * 1000) + xInputWithFee;
        return numerator / denominator;
    }

    function getLiquidity(address lp) public view returns (uint256 lpLiquidity) {
        return liquidity[lp];
    }

    function ethToToken() public payable returns (uint256 tokenOutput) {
        require(msg.value > 0, "cannot swap 0 ETH");

        uint256 ethReserve = address(this).balance - msg.value;
        uint256 tokenReserve = token.balanceOf(address(this));

        tokenOutput = price(msg.value, ethReserve, tokenReserve);
        require(tokenOutput > 0, "not enough output");

        bool success = token.transfer(msg.sender, tokenOutput);
        if (!success) revert TokenTransferFailed();

        emit EthToTokenSwap(msg.sender, "ETH to Token", msg.value, tokenOutput);
        return tokenOutput;
    }

    function tokenToEth(uint256 tokenInput) public returns (uint256 ethOutput) {
        require(tokenInput > 0, "cannot swap 0 tokens");

        uint256 ethReserve = address(this).balance;
        uint256 tokenReserve = token.balanceOf(address(this));

        ethOutput = price(tokenInput, tokenReserve, ethReserve);
        require(ethOutput > 0, "not enough output");

        bool tokenSuccess = token.transferFrom(msg.sender, address(this), tokenInput);
        if (!tokenSuccess) revert TokenTransferFailed();

        (bool ethSuccess, ) = msg.sender.call{value: ethOutput}("");
        if (!ethSuccess) revert TransferFailed();

        emit TokenToEthSwap(msg.sender, "Token to ETH", tokenInput, ethOutput);
        return ethOutput;
    }

    function deposit() public payable returns (uint256 tokensDeposited) {
        require(msg.value > 0, "Must deposit ETH");

        uint256 ethReserve = address(this).balance - msg.value;
        uint256 tokenReserve = token.balanceOf(address(this));

        tokensDeposited = (msg.value * tokenReserve) / ethReserve;
        uint256 liquidityMinted = (msg.value * totalLiquidity) / ethReserve;

        liquidity[msg.sender] += liquidityMinted;
        totalLiquidity += liquidityMinted;

        bool success = token.transferFrom(msg.sender, address(this), tokensDeposited);
        if (!success) revert TokenTransferFailed();

        emit LiquidityProvided(msg.sender, liquidityMinted, msg.value, tokensDeposited);
        return tokensDeposited;
    }

    function withdraw(uint256 amount) public returns (uint256 ethAmount, uint256 tokenAmount) {
        if (liquidity[msg.sender] < amount) revert InsufficientLiquidity();

        uint256 ethReserve = address(this).balance;
        uint256 tokenReserve = token.balanceOf(address(this));

        ethAmount = (amount * ethReserve) / totalLiquidity;
        tokenAmount = (amount * tokenReserve) / totalLiquidity;

        liquidity[msg.sender] -= amount;
        totalLiquidity -= amount;

        bool tokenSuccess = token.transfer(msg.sender, tokenAmount);
        if (!tokenSuccess) revert TokenTransferFailed();

        (bool ethSuccess, ) = msg.sender.call{value: ethAmount}("");
        if (!ethSuccess) revert TransferFailed();

        emit LiquidityRemoved(msg.sender, amount, ethAmount, tokenAmount);
        return (ethAmount, tokenAmount);
    }
}
