// SPDX-License-Identifier: MIT
pragma solidity >=0.6.9 <0.9.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20CappedUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20VotesUpgradeable.sol";
import "./interfaces/IArbToken.sol";

contract UlsTokenL2ArbitrumOne is
    Initializable,
    ERC20Upgradeable,
    ERC20BurnableUpgradeable,
    ERC20CappedUpgradeable,
    ERC20PermitUpgradeable,
    ERC20VotesUpgradeable
{
    function __UlsTokenL2ArbitrumOne_init() internal onlyInitializing {
        __UlsTokenL2ArbitrumOne_init_unchained();
    }

    function __UlsTokenL2ArbitrumOne_init_unchained()
        internal
        onlyInitializing
    {
        __ERC20_init("UNITS LIMITED SUPPLY", "ULS");
        __ERC20Burnable_init();
        __ERC20Capped_init(10_000_000 * 10 ** decimals());
        __ERC20Permit_init("UNITS LIMITED SUPPLY");
        __ERC20Votes_init();
    }

    function version() external view virtual returns (uint8) {
        return _getInitializedVersion();
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20Upgradeable, ERC20VotesUpgradeable) {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(
        address to,
        uint256 amount
    )
        internal
        virtual
        override(
            ERC20Upgradeable,
            ERC20CappedUpgradeable,
            ERC20VotesUpgradeable
        )
    {
        super._mint(to, amount);
    }

    function _burn(
        address account,
        uint256 amount
    ) internal virtual override(ERC20Upgradeable, ERC20VotesUpgradeable) {
        super._burn(account, amount);
    }
}

contract UlsTokenL2ArbitrumOneV1 is UlsTokenL2ArbitrumOne, IArbToken {
    address private _l2Gateway;
    address private _l1Address;

    function initialize() public virtual initializer {
        __UlsTokenL2ArbitrumOne_init();

        _l2Gateway = 0x096760F208390250649E3e8763348E783AEF5562;
        _l1Address = 0x0cdBbc7FE1c8Da0cc41BA96d7EDB4ccE5982F23f;
    }

    modifier onlyGateway() {
        require(msg.sender == _l2Gateway, "ONLY_l2GATEWAY");
        _;
    }

    function l2Gateway() external view virtual returns (address) {
        return _l2Gateway;
    }

    function l1Address() external view virtual override returns (address) {
        return _l1Address;
    }

    function bridgeMint(
        address account,
        uint256 amount
    ) external virtual override onlyGateway {
        _mint(account, amount);
    }

    function bridgeBurn(
        address account,
        uint256 amount
    ) external virtual override onlyGateway {
        _burn(account, amount);
    }
}
