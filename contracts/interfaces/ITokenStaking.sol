// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

interface ITokenStaking {
    /**
     * @param totalStaked amount of UlsToken currently staked
     * @param historicalRewardRate how many UlsToken minted per one UlsToken (<< 40). Never decreases.
     */
    struct State {
        uint128 totalStaked;
        uint128 historicalRewardRate;
    }

    /**
     * @param amount of UlsToken currently staked by the staker
     * @param initialRewardRate value of historicalRewardRate before last update of the staker's data
     * @param reward total amount of UlsToken accrued to the staker
     * @param claimedReward total amount of UlsToken the staker transferred from the service already
     */
    struct Staker {
        uint256 amount;
        uint128 initialRewardRate;
        uint128 reward;
        uint256 claimedReward;
    }

    // Events
    /// @dev Someone is staked UlsToken
    event Staked(address indexed owner, uint256 amount);
    /// @dev Someone unstaked UlsToken
    event Unstaked(address indexed from, address indexed to, uint256 amount);
    // @dev Someone transferred UlsToken from the service
    event Rewarded(address indexed from, address indexed to, uint256 amount);
    /// @dev UlsToken accrued to the staker
    event StakingBonusAccrued(address indexed staker, uint256 amount);
}
