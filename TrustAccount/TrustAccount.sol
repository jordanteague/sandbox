// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.13;

import './Owned.sol';
import './IERC20minimal.sol';
import './ReentrancyGuard.sol';
import './SafeTransferLib.sol';

// @notice Very simple implementation of a trust account.
contract TrustAccount is Owned, ReentrancyGuard {

    using SafeTransferLib for address;

    mapping(address => uint256) public assigned; // assigned balances by token
    mapping(address => mapping(address => uint256)) accounts; // client -> asset -> balance

    error InsufficientBalance();

    constructor() Owned(msg.sender) {

    }

    function deposit(address asset, uint256 amount) public payable nonReentrant {
        if(asset == address(0)) {
          _accounting(msg.sender, asset, msg.value);
        } else {
          asset._safeTransferFrom(msg.sender, address(this), amount);
          _accounting(msg.sender, asset, amount);          
        }
    }

    function manualAccounting(address client, address asset, uint256 amount) public nonReentrant onlyOwner {
        _accounting(msg.sender, asset, amount);
    }

    function disburse(address client, address asset, uint256 amount, address to) public payable nonReentrant onlyOwner {
        if(accounts[client][asset] < amount) revert InsufficientBalance();
        accounts[client][asset] -= amount;
        assigned[asset] -= amount;
        
        if(asset == address(0)) {
            to._safeTransferETH(amount);
        } else {
            asset._safeTransfer(to, amount);
        }
    }

    // @author allow owner to make arbitrary calls to fix any unanticipated errors
    function call(address _contract, bytes memory payload) public payable nonReentrant onlyOwner {
        _contract.call{value: msg.value} (payload);
    }

    receive() external payable virtual {
        _accounting(msg.sender, address(0), msg.value);
    }

    function _accounting(address client, address asset, uint256 amount) internal {
        if(asset != address(0)) {
          uint256 balance = IERC20minimal(asset).balanceOf(address(this));
          uint256 unassigned = balance - assigned[asset];
          if(unassigned < amount) revert InsufficientBalance();          
        }

        accounts[client][asset] += amount;
        assigned[asset] += amount;
    }

}
