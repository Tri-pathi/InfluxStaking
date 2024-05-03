// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "./Interface/IInfluxStaking.sol";

/**
 * @title InfluxStaking
 * @dev A contract for staking tokens and earning rewards
 */
contract InfluxStaking is IInfluxStaking, Ownable2Step {
    using SafeERC20 for IERC20;

    // state Variables
    IERC20 stakingToken; // The token being staked
    uint256 public constant MIN_STAKE = 0.005 ether; // Minimum stake allowed
    uint256 globalEmissionRate; // Global emission rate of rewards
    uint256 startingTimestamp; // Timestamp when the staking starts
    uint256 lastRewardTimestamp; // Timestamp of the last reward update
    uint256 accRewardPerToken; // Accumulated reward per staked token

    // Mapping to store staker information
    mapping(address => Staker) public stakerInfo;

    constructor(address _stakingToken) Ownable(msg.sender) {
        stakingToken = IERC20(_stakingToken);
        startingTimestamp = block.timestamp;
        globalEmissionRate = 400* 1e18;// we can change later
    }

    /**
     * @dev Function to stake tokens
     * @param amount The amount of tokens to stake
     */
    function stake(uint256 amount) external {
        require(amount > 0, "InvalidAmount");
        updateVault();
        Staker storage user = stakerInfo[msg.sender];
        if (user.amount > 0) {
            uint256 pendingReward = user.amount *
                accRewardPerToken -
                user.rewardDebt;

            user.rewardsPoint += pendingReward;
            emit RewardClaimed(msg.sender, pendingReward);
        }
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);

        user.amount += amount;
        user.rewardDebt = user.amount * accRewardPerToken;
        emit Staked(msg.sender, amount);
    }

    /**
     * @dev Function to unstake tokens
     * @param amount The amount of tokens to unstake
     */
    function unstake(uint256 amount) external {
        Staker storage user = stakerInfo[msg.sender];
        require(amount > 0 && amount <= user.amount, "Invalid amount");
        updateVault();
        uint256 pendingReward = user.amount *
            accRewardPerToken -
            user.rewardDebt;

        user.rewardsPoint += pendingReward;
        emit RewardClaimed(msg.sender, pendingReward);

        user.amount -= amount;
        user.rewardDebt = user.amount * accRewardPerToken;

        stakingToken.safeTransfer(msg.sender, amount);

        emit UnStaked(msg.sender, amount);
    }

    /**
     * @dev Function to update vault and calculate rewards
     */
    function updateVault() public {
        if (block.timestamp <= lastRewardTimestamp) {
            return;
        }

        uint256 totalBalance = stakingToken.balanceOf(address(this));
        if (totalBalance == 0) {
            lastRewardTimestamp = block.timestamp;
            return;
        }
        uint256 timeInterval = block.timestamp - lastRewardTimestamp;
        uint reward = globalEmissionRate * timeInterval;

        accRewardPerToken = accRewardPerToken + reward / totalBalance;

        lastRewardTimestamp = block.timestamp;
    }

    /**
     * @dev Function to calculate pending reward points.
            No state change happens in this function. State change will only happen when user stakes or unstake staking tokens
     * @return The pending reward points for the caller
     */


    function PendingRewardsPoints() external view returns (uint256) {
        uint256 totalBalance = stakingToken.balanceOf(address(this));
        uint256 accPoints = accRewardPerToken;
        if (block.timestamp > lastRewardTimestamp && totalBalance != 0) {
            uint256 timeInterval = block.timestamp - lastRewardTimestamp;
            uint256 reward = globalEmissionRate * timeInterval;
            accPoints = accPoints + (reward / totalBalance);
        }

        return
            stakerInfo[msg.sender].amount *
            accPoints -
            stakerInfo[msg.sender].rewardDebt;
    }

    /**
     * @dev Function to update the emission rate - only the DAO or admin can call this function
     * @param rate The new emission rate
     */
    function setEmissionRate(uint256 rate) external onlyOwner {
        globalEmissionRate = rate;

        emit GlobalEmissionRateUpdated(rate);
    }
    /**
     * @dev Function to get the timestamp of the last reward update
     * @return The timestamp of the last reward update
     */
    function getlastRewardTimestamp() external view returns (uint256) {
        return lastRewardTimestamp;
    }

    /**
     * @dev Function to get the staked amount of a user
     * @param user The address of the user
     * @return The amount of tokens staked by the user
     */
    function getUserStakedAmount(address user) external view returns (uint256) {
        return stakerInfo[user].amount;
    }

    /**
     * @dev Function to get the accumulated reward points of a user, will give recent update value during stake change tx
     * @param user The address of the user
     * @return The accumulated reward points of the user
     */
    function getUserAccRewardPoints(
        address user
    ) external view returns (uint256) {
        return stakerInfo[user].rewardsPoint;
    }
    /**
     * @dev Function to get the reward debt of a user
     * @param user The address of the user
     * @return The reward debt of the user
     */
    function getUserRewardDebt(address user) external view returns (uint256) {
        return stakerInfo[user].rewardDebt;
    }
}
