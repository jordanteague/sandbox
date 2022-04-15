// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

// @author Experimental "poison pill" framework for ERC20 token, preventing a single wallet from holding more than a specified percentage of maxSupply.  
// @author Would be most effective in context where wallet addresses are tied to unique individuals, and where tokenholders vote on mint/transfer occurring.

import "./ERC20.sol";

contract PoisonPill is ERC20 {

    uint256 public maxSupply;
    uint128 public price;
    uint128 public ratio;

    error RatioBounds();
    error MaxSupply();
    error MaxQuantity();
    error WrongAmount();

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _maxSupply,
        uint128 _price,
        uint128 _ratio
    ) ERC20(_name, _symbol, 18) {
        if(_ratio > 100 || _ratio < 1) revert RatioBounds();
        ratio = _ratio;
        maxSupply = _maxSupply;
        price = _price;
    }

    function transfer(address to, uint256 amount) public override returns(bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        _adjustBalances(to);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        _adjustBalances(to);

        return true;
    }

    function mint(address to, uint256 amount) external payable returns(bool) {
        if(totalSupply + amount > maxSupply) revert MaxSupply();
        if(balanceOf[to] + amount > (maxSupply / ratio)) revert MaxQuantity();
        if(price * amount != msg.value) revert WrongAmount();

        _mint(to, amount);

        return true;
    }

    function _adjustBalances(address to) internal returns(bool) {
        if(balanceOf[to] > maxSupply / ratio) {
            uint256 excess = balanceOf[to] - (maxSupply / ratio);
            _burn(to, excess);
        }

        return true;
    }

}
