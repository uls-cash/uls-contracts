// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

/**
 * @dev Interface to got minted Token.
 */
interface ITokenSupplier {
    /**
     * @dev If caller is owner of any mint pool it will be supplied with UlsToken
     * based on the schedule and time passed from the moment
     * when the method was invoked by the same mint pool owner last time.
     * @param maxTime The upper limit of the time to make calculations.
     */
    function supplyToken(uint40 maxTime) external returns (uint256);

    function supplyTokenView(
        uint40 maxTime
    ) external view returns (uint256 supply);
}
