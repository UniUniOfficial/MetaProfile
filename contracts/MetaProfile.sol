// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";


contract MetaProfile is ERC721, ERC721Enumerable, Ownable {
    // Generate Token ID
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // Mapping from Token ID to soul address
    mapping(uint256 => address) private _souls;

    // Mint status, if false, no more nft is allowed to mint
    bool public mintPermitted = true;

    // base uri
    string private _tokenBaseURI;

    constructor() ERC721("Resume NFT", "RNFT") {
        setBaseURI("https://uniuni.network/nft/profile/");
    }

    /**
     * @dev Everyone can mint his/her own profile nft.
     */
    function mint() external {
        require(mintPermitted, "Mint: the NFT contract is locked up forever");
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(msg.sender, tokenId);
        _souls[tokenId] = msg.sender;
    }
    
    /**
     * @dev Everyone can burn his/her own profile NFT
     */
    function burn(uint256 tokenId) external {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _burn(tokenId);
        // not do delete action actually so as to save gas fee
        // delete _souls[tokenId];
    }

    /**
     * @dev After the call, no NFT is allowed to mint
     */
    function lockup() external onlyOwner {
        mintPermitted = false;
    }

    /**
     * @dev Get the soul address of an NFT, require the NFT exists
     * @param tokenId The NFT
     */
    function soulOf(uint256 tokenId) external view returns(address) {
        require(_exists(tokenId), "ERC721: invalid token ID");
        return _souls[tokenId];
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev Set Base URI for computing {tokenURI}.
     */
    function setBaseURI(string memory uri) public onlyOwner {
        _tokenBaseURI = uri;
    }

    /**
     * @dev Base URI for computing {tokenURI}.
     */
    function _baseURI() internal view override virtual returns (string memory) {
        return _tokenBaseURI;
    }
}
