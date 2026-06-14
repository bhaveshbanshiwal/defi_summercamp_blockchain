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
        uint256 amountOfTokens = 100;
        yourToken.transfer(msg.sender, amountOfTokens);
    }
}
