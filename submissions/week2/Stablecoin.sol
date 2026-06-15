//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
contract Stablecoin is ERC20 {
    constructor() ERC20("Stablecoin", "USD") {
        _mint(msg.sender, 1000000 * 10**18);
    }
}
