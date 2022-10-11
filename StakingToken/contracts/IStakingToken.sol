// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the StakingToken
 */
interface IStakingToken {
    event RewardRate(uint256 new_reward_rate);

    event WithdrawReward(uint256 amount, address to);

    event WithdrawStake(uint256 amount, address to);

    event DepositStake(uint256 amount, address from);

    /**
     * @dev x
     */
    function totalSupplyPending() external returns (uint256);

    function setRewardRate(uint256 new_reward_rate) external returns (bool);

    function getClaimableReward() external returns (uint256);

    function withdrawReward(uint256 amount) external returns (bool);

    function withdrawRewardTo(uint256 amount, address to)
        external
        returns (bool);

    function depositStake(uint256 amount) external returns (bool);

    function withdrawStake(uint256 amount) external returns (bool);

    function getStakedBalance() external view returns (uint256);
}
