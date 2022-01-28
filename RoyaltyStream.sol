// SPDX-License-Identifier: MIT

// @notice Simple stream for royalty payments made in ETH, which need to be split among multiple stakeholders.
pragma solidity ^0.8.10;

contract RoyaltyStream {

    uint16 public totalAccounts;

    uint256 public totalRoyalties;

    mapping(uint16 => Account) public accounts;

    struct Account {
        address wallet;
        uint8 percentage;
        uint256 royalties;
        uint256 withdrawn;
    }

    constructor(address[] memory wallets, uint8[] memory percentages) {
        require(wallets.length == percentages.length, "NO_ARRAY_PARITY");

        uint8 sum = 0;
        for(uint i=0; i < percentages.length; i++) {
            sum += percentages[i];
        }
        require(sum == 100, "INVALID_ROYALTY_DISTRIBUTION");
        
        for(uint16 i=0; i < percentages.length; i++) {
            Account memory account = Account({
                wallet: wallets[i],
                percentage: percentages[i],
                royalties: 0,
                withdrawn: 0
            });
            accounts[i] = account;
        }

        totalAccounts = uint16(wallets.length);

    }

    fallback () external payable {
        this.deposit();
    }

    receive() external payable {
        this.deposit();
    }

    function deposit() external payable {
        totalRoyalties += msg.value;

        for(uint16 i=0; i < totalAccounts; i++) {
            uint256 royalty = (accounts[i].percentage * msg.value) / 100;
            accounts[i].royalties += royalty;
        }
    }

    function withdraw(uint16 account, uint256 amount) external {
        require(accounts[account].wallet == msg.sender, "NOT_AUTHORIZED");
        require(accounts[account].royalties - accounts[account].withdrawn >= amount, "INSUFFICENT_BALANCE");
        accounts[account].withdrawn += amount;
        payable(msg.sender).transfer(amount);
    }

    // *** VIEW FUNCTIONS FOR STRUCT *** //

    function viewAccountAddress(uint16 account) external view returns(address) {
        return(accounts[account].wallet);
    }

    function viewTotalRoyalties(uint16 account) external view returns(uint256) {
        return(accounts[account].royalties);
    }

    function viewWithdrawnRoyalties(uint16 account) external view returns(uint256) {
        return(accounts[account].withdrawn);
    }

    function viewBalance(uint16 account) external view returns(uint256) {
        return(accounts[account].royalties - accounts[account].withdrawn);
    }

}
