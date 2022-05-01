// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

import "./ERC721.sol";
import "./LexOwnable.sol";

contract NFTip is ERC721, LexOwnable {

    /// @dev EIP-712 variables:
    bytes32 public immutable DOMAIN_SEPARATOR;
    bytes32 public constant SIG_HASH = keccak256("SignIPtransfer(address from, address to, uint256 id, bytes data)");
    mapping(uint256 => address[]) public ipChain;

    constructor(
        string memory _name, 
        string memory _symbol, 
        address _owner
    ) ERC721(_name, _symbol) LexOwnable(_owner) {
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes("NFTcopyright")),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
    }

    function tokenURI(uint256 id) public view override returns (string memory) {

    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public override {

        _beforeTokenTransfer(from, to, id, data);

        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) internal {
        _signIPtransfer(from, to, id, data);
        ipChain[id].push(to);
    }

    function _signIPtransfer(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) internal returns(bool) {
        // decode data into v, r, s
        (
            uint8 v,
            bytes32 r,
            bytes32 s
        ) 
            = abi.decode(data, (uint8, bytes32, bytes32));
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
                            id
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
        _safeMint(to, id, data);
        ipChain[id].push(to);
        // PROJECT OWNER MAY INCLUDE HUMAN-READABLE TRANSFER LANGUAGE HERE.
    }

    function burn(uint256 id) public onlyOwner {
        _burn(id);
        ipChain[id] = [0x0000000000000000000000000000000000000000];
    }

    function getIPchain(uint256 _id) public view returns(address[] memory _chain) {
        _chain = ipChain[_id];
    }

    function getCurrentIPowner(uint256 _id) public view returns(address _currentOwner) {
        uint256 last = ipChain[_id].length - 1;
        _currentOwner = ipChain[_id][last];
    }
}
