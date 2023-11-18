// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

/**
 * @dev kinds of possible pools.
 * @param DEFAULT_VALUE - dummy type for null value.
 * @param PRIMARY - blockchain based staking. All rules are declared in the  contracts.
 */
enum MintPool {
    DEFAULT_VALUE,
    PRIMARY
}

/**
 * @dev current state of the schedule for each MintPool.
 * @param time last invocation time.
 * @param itemIndex index of current item in UlsTokenSchedule.items.
 * @param yearIndex index of current year in current item in UlsTokenSchedule.items.
 * @param yearStartTime start time of the current year.
 * @param nextTickSupply amount of Token to be distributed next second.
 */
struct ScheduleState {
    uint40 time;
    uint8 itemIndex;
    uint16 yearIndex;
    uint40 yearStartTime;
    uint128 nextTickSupply;
}
