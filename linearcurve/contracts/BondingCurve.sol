// SPDX-License-Identifier: GPL-3.0-or-later

// linear bonding curve
pragma solidity >=0.8.13;

import "./ERC20.sol";

contract BondingCurve is ERC20 {
    uint256 public startingPrice; // wei

    uint8 public curve; // ex. if 5, curve = (x / 5)

    constructor() ERC20('MyDAO', 'TEST', 18) {
        startingPrice = 10000; // hardcoded values for ease of test deployment

        curve = 5;
    }

    function buy(uint256 amount_) public payable {
        uint256 estPrice = estimatePrice(amount_);

        require(msg.value >= estPrice, 'INSUFFICIENT_FUNDS');

        _mint(msg.sender, amount_);
    }

    function estimatePrice(uint256 amount_) public view returns (uint256) {

        uint start = totalSupply;

        uint end = totalSupply + amount_;

        // find definite integral
        uint endIntegral = (startingPrice * end) + (end**2 / (curve * 2));
        uint startIntegral = (startingPrice * start) + (start**2 / (curve * 2));

        uint estTotal = endIntegral - startIntegral;

        return estTotal;
    }
}
