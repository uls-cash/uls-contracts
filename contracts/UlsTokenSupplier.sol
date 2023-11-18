// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./utils/Lib.sol";
import "./utils/ABDKMath64x64.sol";
import "./interfaces/ITokenSchedule.sol";
import "./interfaces/ITokenSupplier.sol";

contract UlsTokenSupplier is Ownable, ITokenSupplier {
    using ABDKMath64x64 for int128;
    using SafeERC20 for IERC20;

    // 365 days = 365 * 24 * 60 * 60 = 31536000 seconds
    uint40 public constant YEAR_DURATION = 365 * 24 * 60 * 60;

    /// @dev UlsToken contract
    IERC20 public immutable token;

    /// @dev UlsTokenSchedule contract
    ITokenSchedule public immutable tokenSchedule;
    ScheduleState public tokenScheduleState;

    /// @dev UlsTokenStaking contract
    address public tokenStaking;
    int128 public immutable tokenStakingShare;

    constructor(address token_, address tokenSchedule_) {
        token = IERC20(token_);
        tokenSchedule = ITokenSchedule(tokenSchedule_);

        // ABDKMath64x64.fromInt(1) = 18446744073709551616
        tokenStakingShare = 18446744073709551616;

        tokenScheduleState.time = 0;
        tokenScheduleState.yearStartTime = 0;
        tokenScheduleState.nextTickSupply =
            2_360_679_774997896964574700 /
            YEAR_DURATION;
    }

    function setTokenStaking(address tokenStaking_) external onlyOwner {
        require(
            tokenStaking == address(0),
            "UlsTokenSupplier: staking already set"
        );
        require(tokenStaking_ != address(0), "UlsTokenSupplier: zero address");
        tokenStaking = tokenStaking_;
    }

    function setStartTime(uint40 startTime) external onlyOwner {
        require(
            tokenScheduleState.time == 0,
            "UlsTokenSupplier: start time already set"
        );
        require(
            startTime >= uint40(block.timestamp),
            "UlsTokenSupplier: incorrect start time"
        );
        tokenScheduleState.time = startTime;
        tokenScheduleState.yearStartTime = startTime;
    }

    function supplyToken(
        uint40 maxTime
    ) external override returns (uint256 supply) {
        if (_msgSender() != tokenStaking) return 0;

        uint256 supplyTotal = _supplyToken(maxTime);
        supply = ABDKMath64x64.mulu(tokenStakingShare, supplyTotal);

        token.safeTransfer(_msgSender(), supply);
        return supply;
    }

    function supplyTokenView(
        uint40 maxTime
    ) external view override returns (uint256 supply) {
        if (_msgSender() != tokenStaking) return 0;

        uint256 supplyTotal = _supplyTokenView(maxTime);
        supply = ABDKMath64x64.mulu(tokenStakingShare, supplyTotal);
        return supply;
    }

    /**
     * @dev if caller is owner of any mint pool it will be supplied with Token
     * based on the schedule and time passed from the moment
     * when the method was invoked by the same mint pool owner last time.
     * @param maxTime the upper limit of the time to make calculations.
     */
    function _supplyToken(uint40 maxTime) private returns (uint256) {
        if (tokenScheduleState.time == 0) {
            return 0;
        }

        if (maxTime > uint40(block.timestamp)) {
            maxTime = uint40(block.timestamp);
        }
        (uint256 supply, ScheduleState memory newState) = tokenSchedule
            .makeProgress(tokenScheduleState, maxTime, MintPool.PRIMARY);
        tokenScheduleState = newState;
        return supply;
    }

    function _supplyTokenView(uint40 maxTime) private view returns (uint256) {
        if (tokenScheduleState.time == 0) {
            return 0;
        }

        if (maxTime > uint40(block.timestamp)) {
            maxTime = uint40(block.timestamp);
        }
        ScheduleState memory state = tokenScheduleState;
        (uint256 supply, ) = tokenSchedule.makeProgress(
            state,
            maxTime,
            MintPool.PRIMARY
        );
        return supply;
    }

    /// @dev View function to support displaying PRIMARY POOL daily supply on UI.
    function rewardRate() external view returns (uint256) {
        if (tokenScheduleState.time == 0) {
            return 0;
        }

        (, ScheduleState memory newState) = tokenSchedule.makeProgress(
            tokenScheduleState,
            uint40(block.timestamp),
            MintPool.PRIMARY
        );
        return uint256(newState.nextTickSupply);
    }
}
