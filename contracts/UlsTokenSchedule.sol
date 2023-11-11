// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "./utils/Lib.sol";
import "./utils/ABDKMath64x64.sol";
import "./interfaces/ITokenSchedule.sol";

contract UlsTokenSchedule is ITokenSchedule {
    using ABDKMath64x64 for int128;

    // 365 days = 365 * 24 * 60 * 60 = 31536000 seconds
    uint40 public constant YEAR_DURATION = 365 * 24 * 60 * 60;

    /**
     * @dev structure to describe the mint schedule.
     * After each year ScheduleState.nextTickSupply decreases.
     * When the schedule completes yearCount years in current item it goes to the next item in the items.
     * @param yearCount duration of the item in years.
     * @param yearCompletenessMultiplier a number nextTickSupply is multiplied by after each year in the item.
     * @param poolShares shares of the mint pool in the item.
     */
    struct ScheduleItem {
        uint16 yearCount;
        int128 yearCompletenessMultiplier;
        int128[] poolShares;
    }
    /// @dev array of shcedule describing items
    ScheduleItem[] public items;

    constructor() {
        /**
         * @dev Reward distribution percentage.
         * [0%, 100%]
         * 100% = ABDKMath64x64.divu(1, 1) = 18446744073709551616;
         */
        int128[2] memory poolShares = [int128(0), int128(18446744073709551616)];

        /* period 1-29200 days | duration 80 years (2522880000 seconds) | itemIndex = 0 */
        ScheduleItem storage item = items.push();
        item.yearCount = 80;
        item.poolShares = poolShares;
        /**
         * @dev Decrease in reward every year by ~38% (Golden Ratio).
         * ABDKMath64x64.divu(
         *     10000000000000000000000000000000000000000000000000000000000000000000000000000,
         *     16180339887498948482045868343656381177203091798057628621354486227052604628189
         * ) = 11400714819323198485;
         */
        item.yearCompletenessMultiplier = 11400714819323198485;
    }

    /**
     * @dev Calculates changes in scheduleState based on the time passed from
     * last update and returns updated state and amount of Token to be minted.
     */
    function makeProgress(
        ScheduleState memory scheduleState,
        uint40 time,
        MintPool pool
    )
        external
        view
        override
        returns (uint256 tokenSupply, ScheduleState memory)
    {
        if (time <= scheduleState.time) return (0, scheduleState);
        while (
            time > scheduleState.time && scheduleState.itemIndex < items.length
        ) {
            ScheduleItem storage item = items[scheduleState.itemIndex];
            uint40 boundary = _min(
                time,
                scheduleState.yearStartTime + YEAR_DURATION
            );
            uint256 secondsFromLastUpdate = boundary - scheduleState.time;
            tokenSupply +=
                secondsFromLastUpdate *
                item.poolShares[uint256(pool)].mulu(
                    uint256(scheduleState.nextTickSupply)
                );
            _persistStateChange(scheduleState, item, boundary);
        }
        return (tokenSupply, scheduleState);
    }

    function _persistStateChange(
        ScheduleState memory state,
        ScheduleItem memory item,
        uint40 time
    ) private pure {
        state.time = time;
        if (time == state.yearStartTime + YEAR_DURATION) {
            state.nextTickSupply = uint128(
                item.yearCompletenessMultiplier.mulu(
                    uint256(state.nextTickSupply)
                )
            );
            state.yearIndex++;
            state.yearStartTime = time;
            if (state.yearIndex == item.yearCount) {
                state.yearIndex = 0;
                state.itemIndex++;
            }
        }
    }

    function _min(uint40 a, uint40 b) private pure returns (uint40) {
        if (a < b) return a;
        return b;
    }
}
