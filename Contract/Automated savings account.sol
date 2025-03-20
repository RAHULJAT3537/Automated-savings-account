// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract AutomatedSavings {
    struct Account {
        uint256 balance;
        uint256 lastDepositTime;
        uint256 interestRate; // Annual interest in basis points (e.g., 500 = 5%)
        uint256 lockPeriod; // Lock period in seconds (e.g., 30 days)
    }
    
    mapping(address => Account) public accounts;
    address public owner;
    uint256 public penaltyRate = 200; // 2% penalty on early withdrawal

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount, bool isPenalty);

    constructor() {
        owner = msg.sender;
    }

    function deposit(uint256 _lockPeriod, uint256 _interestRate) external payable {
        require(msg.value > 0, "Deposit must be greater than zero");
        Account storage acc = accounts[msg.sender];
        
        acc.balance += msg.value;
        acc.lastDepositTime = block.timestamp;
        acc.lockPeriod = _lockPeriod;
        acc.interestRate = _interestRate;
        
        emit Deposited(msg.sender, msg.value);
    }

    function calculateInterest(address _user) public view returns (uint256) {
        Account storage acc = accounts[_user];
        uint256 timeElapsed = block.timestamp - acc.lastDepositTime;
        return (acc.balance * acc.interestRate * timeElapsed) / (365 days * 10000);
    }

    function withdraw() external {
        Account storage acc = accounts[msg.sender];
        require(acc.balance > 0, "No funds available");
        
        uint256 withdrawAmount = acc.balance + calculateInterest(msg.sender);
        bool isPenalty = block.timestamp < acc.lastDepositTime + acc.lockPeriod;
        
        if (isPenalty) {
            uint256 penalty = (withdrawAmount * penaltyRate) / 10000;
            withdrawAmount -= penalty;
        }
        
        acc.balance = 0;
        payable(msg.sender).transfer(withdrawAmount);
        emit Withdrawn(msg.sender, withdrawAmount, isPenalty);
    }
}

