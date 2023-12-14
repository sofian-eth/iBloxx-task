// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract DummyERC721 is ERC721 {
    uint256 private _nextTokenId;

    constructor() ERC721("Dummy ERC721", "D721") {
        safeMint(msg.sender);
        safeMint(msg.sender);
        safeMint(msg.sender);
    }

    function safeMint(address to) public {
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
    }
}
