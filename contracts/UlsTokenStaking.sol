// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/ITokenStaking.sol";
import "./interfaces/IToken.sol";
import "./interfaces/ITokenSupplier.sol";

contract UlsTokenStaking is Context, ITokenStaking {
    using SafeERC20 for IToken;

    /// @dev UlsToken contract
    IToken public immutable token;

    /// @dev UlsTokenSupplier contract
    ITokenSupplier public immutable tokenSupplier;

    address private immutable _deadAddress;

    /// @dev Internal service state
    State public state;

    /// @dev Mapping of staker's address to its state
    mapping(address => Staker) public stakers;

    constructor(address token_, address tokenSupplier_) {
        token = IToken(token_);
        tokenSupplier = ITokenSupplier(tokenSupplier_);
        _deadAddress = 0x000000000000000000000000000000000000dEaD;
    }

    /**
     * @dev Function to stake permitted amount of UlsToken
     * @param amount of UlsToken to be staked in the service
     */
    function stake(uint256 amount) external {
        _stakeFrom(_msgSender(), amount);
    }

    function stakeWithPermit(
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        token.safePermit(
            _msgSender(),
            address(this),
            amount,
            deadline,
            v,
            r,
            s
        );
        _stakeFrom(_msgSender(), amount);
    }

    function stakeFrom(address owner, uint256 amount) external {
        _stakeFrom(owner, amount);
    }

    function _stakeFrom(address owner, uint256 amount) private {
        token.safeTransferFrom(owner, address(this), amount);

        Staker storage staker = _updateStateAndStaker(owner);

        emit Staked(owner, amount);
        state.totalStaked += uint128(amount);
        staker.amount += amount;
    }

    /**
     * @dev Function to unstake UlsToken from the service
     * @param amount of UlsToken to be unstaked from the service
     */
    function unstake(uint256 amount) external {
        _unstake(_msgSender(), _msgSender(), amount);
    }

    function unstakeTo(address to, uint256 amount) external {
        _unstake(_msgSender(), to, amount);
    }

    function _unstake(address from, address to, uint256 amount) private {
        Staker storage staker = _updateStateAndStaker(from);
        require(staker.amount >= amount, "UlsTokenStaking: NOT_ENOUGH_STAKED");

        emit Unstaked(from, to, amount);
        state.totalStaked -= uint128(amount);
        staker.amount -= amount;

        token.safeTransfer(to, amount);
    }

    /**
     * @dev Updates current reward and transfers it to the caller's address
     */
    function claimReward() external returns (uint256) {
        Staker storage staker = _updateStateAndStaker(_msgSender());
        assert(staker.reward >= staker.claimedReward);
        uint128 unclaimedReward = staker.reward - uint128(staker.claimedReward);
        _claimReward(staker, _msgSender(), _msgSender(), unclaimedReward);
        return unclaimedReward;
    }

    function claimRewardTo(address to) external returns (uint256) {
        Staker storage staker = _updateStateAndStaker(_msgSender());
        assert(staker.reward >= staker.claimedReward);
        uint128 unclaimedReward = staker.reward - uint128(staker.claimedReward);
        _claimReward(staker, _msgSender(), to, unclaimedReward);
        return unclaimedReward;
    }

    function claimRewardToWithoutUpdate(address to) external returns (uint256) {
        Staker storage staker = stakers[_msgSender()];
        assert(staker.reward >= staker.claimedReward);
        uint128 unclaimedReward = staker.reward - uint128(staker.claimedReward);
        _claimReward(staker, _msgSender(), to, unclaimedReward);
        return unclaimedReward;
    }

    function _updateStateAndStaker(
        address stakerAddress
    ) private returns (Staker storage staker) {
        updateHistoricalRewardRate();
        staker = stakers[stakerAddress];

        uint128 unrewarded = uint128(
            ((state.historicalRewardRate - staker.initialRewardRate) *
                staker.amount) >> 40
        );
        emit StakingBonusAccrued(stakerAddress, unrewarded);

        staker.initialRewardRate = state.historicalRewardRate;
        staker.reward += unrewarded;
    }

    function _updateStateAndStakerView(
        address stakerAddress
    ) private view returns (Staker memory staker) {
        uint128 historicalRewardRate = _updateHistoricalRewardRateView();
        staker = stakers[stakerAddress];

        uint128 unrewarded = uint128(
            ((historicalRewardRate - staker.initialRewardRate) *
                staker.amount) >> 40
        );

        staker.reward += unrewarded;
    }

    function _claimReward(
        Staker storage staker,
        address from,
        address to,
        uint128 amount
    ) private {
        assert(staker.reward >= staker.claimedReward);
        uint128 unclaimedReward = staker.reward - uint128(staker.claimedReward);
        require(
            amount <= unclaimedReward,
            "UlsTokenStaking: NOT_ENOUGH_BALANCE"
        );
        emit Rewarded(from, to, amount);
        staker.claimedReward += amount;
        token.safeTransfer(to, amount);
    }

    function restake() external {
        Staker storage staker = _updateStateAndStaker(_msgSender());
        assert(staker.reward >= staker.claimedReward);

        uint128 unclaimedReward = staker.reward - uint128(staker.claimedReward);
        emit Rewarded(_msgSender(), _msgSender(), unclaimedReward);
        staker.claimedReward += unclaimedReward;

        emit Staked(_msgSender(), unclaimedReward);
        state.totalStaked += unclaimedReward;
        staker.amount += unclaimedReward;
    }

    /**
     * @dev Updates state and returns unclaimed reward amount.
     * Is supposed to be invoked as call from metamask
     * to display current amount of UlsToken available.
     */
    function getReward() external returns (uint256 unclaimedReward) {
        Staker memory staker = _updateStateAndStaker(_msgSender());
        assert(staker.reward >= staker.claimedReward);
        unclaimedReward = staker.reward - staker.claimedReward;
    }

    function getRewardView(
        address stakerAddress
    ) external view returns (uint256 unclaimedReward) {
        Staker memory staker = _updateStateAndStakerView(stakerAddress);
        assert(staker.reward >= staker.claimedReward);
        unclaimedReward = staker.reward - staker.claimedReward;
    }

    function updateHistoricalRewardRate() public {
        uint256 currentTokenSupply = tokenSupplier.supplyToken(
            uint40(block.timestamp)
        );
        if (currentTokenSupply == 0) return;
        if (state.totalStaked != 0) {
            uint128 additionalRewardRate = uint128(
                (currentTokenSupply << 40) / state.totalStaked
            );
            state.historicalRewardRate += additionalRewardRate;
        } else {
            token.safeTransfer(_deadAddress, currentTokenSupply);
        }
    }

    function _updateHistoricalRewardRateView()
        private
        view
        returns (uint128 historicalRewardRate)
    {
        uint256 currentTokenSupply = tokenSupplier.supplyTokenView(
            uint40(block.timestamp)
        );
        if (currentTokenSupply == 0) return state.historicalRewardRate;
        if (state.totalStaked != 0) {
            uint128 additionalRewardRate = uint128(
                (currentTokenSupply << 40) / state.totalStaked
            );
            return state.historicalRewardRate + additionalRewardRate;
        } else {
            return state.historicalRewardRate;
        }
    }

    function totalStaked() external view returns (uint128) {
        return state.totalStaked;
    }
}
