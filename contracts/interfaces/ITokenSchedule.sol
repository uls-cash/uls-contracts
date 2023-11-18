// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "../utils/Lib.sol";

interface ITokenSchedule {
    /**
     * @dev Calculates changes in scheduleState based on the time passed from
     * last update and returns updated state and amount of Token to be minted.
     */
    function makeProgress(
        ScheduleState memory scheduleState,
        uint40 time,
        MintPool pool
    ) external view returns (uint256 tokenSupply, ScheduleState memory);
}
