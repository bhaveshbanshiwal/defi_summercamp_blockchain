//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
contract DEX {
    IERC20 public token;
    constructor(address tokenAddr) {
        token = IERC20(tokenAddr);
    }
    function init(uint256 tokens) public payable returns (uint256) {
        token.transferFrom(msg.sender, address(this), tokens);
        return tokens;
    }
    function ethToToken() public payable returns (uint256) {
        return 0;
    }
}
