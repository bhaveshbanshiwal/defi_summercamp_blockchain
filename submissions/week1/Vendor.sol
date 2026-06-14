//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;
import "./YourToken.sol";
contract Vendor {
    YourToken public yourToken;
    uint256 public constant tokensPerEth = 100;
    constructor(address tokenAddress) {
        yourToken = YourToken(tokenAddress);
    }
    function buyTokens() public payable {
        uint256 amountOfTokens = msg.value * tokensPerEth;
        yourToken.transfer(msg.sender, amountOfTokens);
    }
    function sellTokens(uint256 amount) public {
        require(yourToken.balanceOf(msg.sender) >= amount, "Not enough tokens");
        uint256 ethAmount = amount / tokensPerEth;
        yourToken.transferFrom(msg.sender, address(this), amount);
        (bool sent, ) = msg.sender.call{value: ethAmount}("");
        require(sent, "Failed to send ETH");
    }
}
