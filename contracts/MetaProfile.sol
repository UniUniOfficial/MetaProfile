// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";


contract MetaProfile is ERC721, ERC721Enumerable, Ownable {
    // Generate Token ID
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // Mapping from token ID to creator
    mapping(uint256 => address) private _creators;

    constructor() ERC721("UniUni MetaProfile", "UUMP") {
    }

    /**
     * @dev Everyone can mint his/her own profile nft.
     */
    function mint() public {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(msg.sender, tokenId);
        _creators[tokenId] = msg.sender;
    }
    
    /**
     * @dev Everyone can burn his/her own profile NFT
     */
    function burn(uint256 tokenId) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _burn(tokenId);
        // not do delete action actually so as to save gas fee
        // delete _creators[tokenId];
    }

    /**
     * @dev Get the creator of an NFT, require the NFT exists
     * @param tokenId The NFT
     */
    function creatorOf(uint256 tokenId) external view returns(address) {
        require(_exists(tokenId), "ERC721: invalid token ID");
        return _creators[tokenId];
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev overrides Base URI for computing {tokenURI}.
     */
    function _baseURI() internal view virtual override(ERC721) returns (string memory) {
        return "https://uniuni.io/nft/profile/";
    }
}