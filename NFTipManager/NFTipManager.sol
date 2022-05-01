// SPDX-License-Identifier: AGPL-3.0-only

// @author Experimental method for complying with "signed writing" requirement under U.S. law for copyright transfer.
pragma solidity 0.8.10;

import "./ERC721.sol";
import "./LexOwnable.sol";

contract NFTipManager is ERC721, LexOwnable {

    event IPtransfer(address from, address to, uint256 id);

    /// @dev EIP-712 variables:
    bytes32 public immutable DOMAIN_SEPARATOR;
    bytes32 public constant SIG_HASH = keccak256("SignIPtransfer(address from, string message)");

    constructor(
        string memory _name, 
        string memory _symbol, 
        address _owner
    ) ERC721(_name, _symbol) LexOwnable(_owner) {
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes("NFTipManager")),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        // TO BE IMPLEMENTED
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public override {
        revert("SIGNATURE_REQUIRED_FOR_TRANSFER");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public override {
        _signIPtransfer(from, to, id, data);

        transferFrom(from, to, id);

        emit IPtransfer(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    // Require transferor to sign message in UI representing that they still own IP and that they consent to transfer
    // Consider storing this signed message offline and/or producing 'document' format for transfer parties' records
    function _signIPtransfer(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) internal returns(bool) {
        // decode data into v, r, s, message
        (
            uint8 v,
            bytes32 r,
            bytes32 s,
            string memory message
        ) 
            = abi.decode(data, (uint8, bytes32, bytes32, string));
        // recover signature
        bytes32 digest =
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR,
                    keccak256(
                        abi.encode(
                            SIG_HASH,
                            from,
                            message
                        )
                    )
                )
            );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress == from, "INVALID_SIG");
        return true;
    }

    // for POC simplicity, minting is restricted to owner, but could instead be pay-walled with a capped supply
    function mint(address to, uint256 id, bytes memory data) public onlyOwner {
        // PROJECT OWNER MAY INCLUDE HUMAN-READABLE TRANSFER LANGUAGE HERE.
        _safeMint(to, id, data);
        emit IPtransfer(address(this), to, id);
    }

    function burn(uint256 id) public onlyOwner {
        _burn(id);
    }
}
