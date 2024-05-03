// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

interface IInfluxStaking {
    // Errors
    error InvalidAmount(); // Error for invalid amount

    // Events
    event Staked(address staker, uint256 amount); // Event for stake action
    event RewardClaimed(address claimer, uint256 rewardPoints); // Event for reward claiming
    event GlobalEmissionRateUpdated(uint256 emissionRate); // Event for emission rate update
    event UnStaked(address caller, uint256 amount); // Event for unstake action

    struct Staker {
        uint256 amount; // Amount of tokens staked
        uint256 rewardsPoint; // Accumulated rewards
        uint256 rewardDebt; // Debt to handle reward calculation
    }

    function stake(uint256 amount) external;

    function unstake(uint256 amount) external;

    function updateVault() external;

    function PendingRewardsPoints() external returns (uint256);
}
