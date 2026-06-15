//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
contract DEX {
    IERC20 public token;
    uint256 public totalLiquidity;
    mapping (address => uint256) public liquidity;
    constructor(address tokenAddr) {
        token = IERC20(tokenAddr);
    }
    function init(uint256 tokens) public payable returns (uint256) {
        token.transferFrom(msg.sender, address(this), tokens);
        liquidity[msg.sender] = address(this).balance;
        totalLiquidity = address(this).balance;
        return tokens;
    }
    function price(uint256 xInput, uint256 xReserves, uint256 yReserves) public pure returns (uint256) {
        uint256 numerator = xInput * yReserves;
        uint256 denominator = xReserves + xInput;
        return numerator / denominator;
    }
    function ethToToken() public payable returns (uint256) {
        uint256 tokenReserve = token.balanceOf(address(this));
        uint256 ethReserve = address(this).balance - msg.value;
        uint256 tokensBought = price(msg.value, ethReserve, tokenReserve);
        token.transfer(msg.sender, tokensBought);
        return tokensBought;
    }
}
