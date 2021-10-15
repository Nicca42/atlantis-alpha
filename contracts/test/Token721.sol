// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract Token721 is ERC721 {

    uint256 private tokenIdCounter_;

    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {}

    function mint(address _to) external {
        tokenIdCounter_ += 1;
        _mint(_to, tokenIdCounter_);
    }

    function burn(uint256 _tokenId) external {
        _burn(_tokenId);
    }
}