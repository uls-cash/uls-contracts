// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "./UlsTokenV1.sol";
import "./interfaces/IArbL1CustomGateway.sol";
import "./interfaces/IArbL1GatewayRouter2.sol";
import "./interfaces/IArbL1CustomToken.sol";

contract UlsTokenV2 is UlsTokenV1, IArbL1CustomToken {
    address public arbOneGateway;
    address public arbOneRouter;
    address public arbOneToken;
    bool internal _shouldRegisterGateway;

    function initialize() public virtual override reinitializer(2) {
        arbOneGateway = 0xcEe284F754E854890e311e3280b767F80797180d;
        arbOneRouter = 0x72Ce9c846789fdB6fC1f34aC4AD25Dd9ef7031ef;
        arbOneToken = 0x0cdBbc7FE1c8Da0cc41BA96d7EDB4ccE5982F23f;
    }

    function balanceOf(
        address account
    )
        public
        view
        virtual
        override(ERC20Upgradeable, IArbL1CustomToken)
        returns (uint256)
    {
        return super.balanceOf(account);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    )
        public
        virtual
        override(ERC20Upgradeable, IArbL1CustomToken)
        returns (bool)
    {
        return super.transferFrom(sender, recipient, amount);
    }

    /// @dev we only set shouldRegisterGateway to true when in `registerTokenOnL2`
    function isArbitrumEnabled()
        external
        view
        virtual
        override
        returns (uint8)
    {
        require(_shouldRegisterGateway, "NOT_EXPECTED_CALL");
        return uint8(0xb1);
    }

    function registerTokenOnL2(
        address l2CustomTokenAddress,
        uint256 maxSubmissionCostForCustomGateway,
        uint256 maxSubmissionCostForRouter,
        uint256 maxGasForCustomGateway,
        uint256 maxGasForRouter,
        uint256 gasPriceBid,
        uint256 valueForGateway,
        uint256 valueForRouter,
        address creditBackAddress
    ) public payable virtual override {
        // we temporarily set `_shouldRegisterGateway` to true for the callback in registerTokenToL2 to succeed
        bool prev = _shouldRegisterGateway;
        _shouldRegisterGateway = true;

        IArbL1CustomGateway(arbOneGateway).registerTokenToL2{
            value: valueForGateway
        }(
            l2CustomTokenAddress,
            maxGasForCustomGateway,
            gasPriceBid,
            maxSubmissionCostForCustomGateway,
            creditBackAddress
        );

        IArbL1GatewayRouter2(arbOneRouter).setGateway{value: valueForRouter}(
            arbOneGateway,
            maxGasForRouter,
            gasPriceBid,
            maxSubmissionCostForRouter,
            creditBackAddress
        );

        _shouldRegisterGateway = prev;
    }
}
