// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "@openzeppelin/contracts/governance/TimelockController.sol";

contract UlsTimelock is TimelockController {
    uint256 private _minDelay = 3 * 24 * 60 * 60;
    address[] private _proposers = [0x3b7B23c1a883a7038E681948fb5FACa51fc03474];
    address[] private _executors = [0x3b7B23c1a883a7038E681948fb5FACa51fc03474];

    address private _admin = address(0);

    constructor()
        TimelockController(_minDelay, _proposers, _executors, _admin)
    {}
}
