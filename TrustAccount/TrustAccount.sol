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

    function assign(address client, address asset, uint256 amount) public nonReentrant onlyOwner {
        uint256 balance = IERC20minimal(asset).balanceOf(address(this));
        uint256 unassigned = balance - assigned[asset];
        if(unassigned < amount) revert InsufficientBalance();
        accounts[client][asset] += amount;
        assigned[asset] += amount;
    }

    function _ethAssign(address client, uint256 amount) internal {
        accounts[client][address(0)] += amount;
        assigned[address(0)] += amount;
    }

    function disburse(address client, address asset, uint256 amount, address to) public payable nonReentrant onlyOwner {
        if(accounts[client][asset] < amount) revert InsufficientBalance();
        accounts[client][address(0)] -= amount;
        assigned[address(0)] -= amount;
        
        if(asset == address(0)) {
            to._safeTransferETH(amount);
        } else {
            asset._safeTransfer(to, amount);
        }
    }

    function call(address _contract, bytes memory payload) public payable nonReentrant onlyOwner {
        _contract.call{value: msg.value} (payload);
    }

    receive() external payable virtual {
        _ethAssign(msg.sender, msg.value);
    }

}
