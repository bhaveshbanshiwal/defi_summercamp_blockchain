// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FiatBackedStablecoin is ERC20, Ownable {
    mapping(address => bool) public isBlacklisted;

    event Blacklisted(address indexed user);
    event UnBlacklisted(address indexed user);

    constructor() ERC20("USD Coin", "USDC") Ownable(msg.sender) {}

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function burn(uint256 amount) external onlyOwner {
        _burn(msg.sender, amount);
    }

    function blacklist(address account) external onlyOwner {
        isBlacklisted[account] = true;
        emit Blacklisted(account);
    }

    function unblacklist(address account) external onlyOwner {
        isBlacklisted[account] = false;
        emit UnBlacklisted(account);
    }

    function _update(address from, address to, uint256 value) internal override {
        require(!isBlacklisted[from], "Sender is blacklisted");
        require(!isBlacklisted[to], "Receiver is blacklisted");
        
        super._update(from, to, value);
    }
}
