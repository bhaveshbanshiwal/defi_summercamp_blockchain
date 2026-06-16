// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LendingPlatform is Ownable {
    IERC20 public collateralToken;
    IERC20 public debtToken;

    mapping(address => uint256) public collaterals;
    mapping(address => uint256) public debts;

    uint256 public constant COLLATERAL_RATIO = 150;

    event Deposited(address indexed user, uint256 amount);
    event Borrowed(address indexed user, uint256 amount);
    event Repaid(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    constructor(address _collateralToken, address _debtToken) Ownable(msg.sender) {
        collateralToken = IERC20(_collateralToken);
        debtToken = IERC20(_debtToken);
    }

    function deposit(uint256 amount) external {
        require(amount > 0, "Amount must be > 0");
        
        collaterals[msg.sender] += amount;
        require(collateralToken.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        
        emit Deposited(msg.sender, amount);
    }

    function borrow(uint256 amount) external {
        require(amount > 0, "Amount must be > 0");
        
        uint256 maxBorrow = (collaterals[msg.sender] * 100) / COLLATERAL_RATIO;
        require(debts[msg.sender] + amount <= maxBorrow, "Insufficient collateral");

        debts[msg.sender] += amount;
        require(debtToken.transfer(msg.sender, amount), "Transfer failed");
        
        emit Borrowed(msg.sender, amount);
    }

    function repay(uint256 amount) external {
        require(amount > 0, "Amount must be > 0");
        require(debts[msg.sender] >= amount, "Repaying more than owed");

        debts[msg.sender] -= amount;
        require(debtToken.transferFrom(msg.sender, address(this), amount), "Transfer failed");

        emit Repaid(msg.sender, amount);
    }

    function withdraw(uint256 amount) external {
        require(amount > 0, "Amount must be > 0");
        require(collaterals[msg.sender] >= amount, "Insufficient balance");

        uint256 remainingCollateral = collaterals[msg.sender] - amount;
        
        uint256 requiredCollateral = (debts[msg.sender] * COLLATERAL_RATIO) / 100;
        require(remainingCollateral >= requiredCollateral, "Withdrawal drops below collateral ratio");

        collaterals[msg.sender] = remainingCollateral;
        require(collateralToken.transfer(msg.sender, amount), "Transfer failed");

        emit Withdrawn(msg.sender, amount);
    }
}
