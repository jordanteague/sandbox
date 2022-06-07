// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import './ERC721.sol';
import './Owned.sol';
import './Strings.sol';

/// @notice Non-transferrable NFT that can be burned only by the contract owner.
contract StickyNFT is ERC721, Owned {

    using Strings for uint256;

    uint256 counter = 0;
    string baseURI;

    constructor(
         string memory _name, 
         string memory _symbol,
         string memory _baseURI // must include trailing slash
        ) 
        ERC721(_name, _symbol) 
        Owned(msg.sender) {
        baseURI = _baseURI;
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, id.toString(), '.json')) : "";
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public pure override {
        revert();
        // no transfer allowed
    } 

    function mint(address to) public onlyOwner {
        _safeMint(to, counter);
        counter++;
    }
    function burn(uint256 id) public onlyOwner {
        _burn(id);
    }

}
