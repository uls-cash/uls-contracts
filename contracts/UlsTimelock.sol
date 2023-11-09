// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "@openzeppelin/contracts/governance/TimelockController.sol";

contract UlsTimelock is TimelockController {
    uint256 private _minDelay = 60; // TODO 3 * 24 * 60 * 60 = 259200 (3 days)
    address[] private _proposers = [address(0)]; // TODO
    address[] private _executors = [address(0)]; // TODO

    address private _admin = address(0);

    constructor()
        TimelockController(_minDelay, _proposers, _executors, _admin)
    {}
}
