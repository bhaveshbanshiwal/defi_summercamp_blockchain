// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./YourToken.sol";

contract Vendor is Ownable {
    error BuyAmountZero();
    error SellAmountZero();
    error TransferFailed();
    error TokenTransferFailed();

    YourToken public immutable yourToken;
    uint256 public constant tokensPerEth = 100;

    event BuyTokens(address buyer, uint256 amountOfETH, uint256 amountOfTokens);
    event SellTokens(address seller, uint256 amountOfTokens, uint256 amountOfETH);

    constructor(address tokenAddress) Ownable(msg.sender) {
        yourToken = YourToken(tokenAddress);
    }

    function buyTokens() external payable {
        if (msg.value == 0) revert BuyAmountZero();

        uint256 amountOfTokens = msg.value * tokensPerEth;

        bool success = yourToken.transfer(msg.sender, amountOfTokens);
        if (!success) revert TokenTransferFailed();

        emit BuyTokens(msg.sender, msg.value, amountOfTokens);
    }

    function withdraw() public onlyOwner {
        uint256 contractBalance = address(this).balance;

        (bool success, ) = msg.sender.call{value: contractBalance}("");
        if (!success) revert TransferFailed();
    }

    function sellTokens(uint256 amount) public {
        if (amount == 0) revert SellAmountZero();

        uint256 amountOfETH = amount / tokensPerEth;

        bool tokenSuccess = yourToken.transferFrom(msg.sender, address(this), amount);
        if (!tokenSuccess) revert TokenTransferFailed();

        (bool ethSuccess, ) = msg.sender.call{value: amountOfETH}("");
        if (!ethSuccess) revert TransferFailed();

        emit SellTokens(msg.sender, amount, amountOfETH);
    }
}
