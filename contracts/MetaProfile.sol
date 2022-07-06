// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";


/*
 * ERC4907 only applies for whole lease pattern
 * But digital crypto NFTs' assets can be leased by many copies of their own
 * So this is a improved interface for multi-copy lease, 
 * and is compatible with with ERC721
 */
contract MetaProfile is ERC721, ERC721Enumerable, Ownable {
    // Generate Token ID
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // Mapping from token ID to whether the NFT is allowed to sublease
    mapping(uint256 => bool) private _subleaseAllowed;

    // Mapping from token ID to the last expires of all the leases
    mapping(uint256 => uint256) private _leaseExpires;

    // Mapping from token ID to the expires of the lease
    mapping(uint256 => mapping(address => uint256)) private _lease;

    /**
     * @notice Emitted when the lease of a NFT happened
     */
    event Lease(uint256 indexed tokenId, address indexed leasee, uint256 expires);

    /**
     * @notice Emitted when the sublease of a NFT happened
     */
    event Sublease(uint256 indexed tokenId, address indexed oldLeasee, address indexed newLeasee, uint256 expires);

    constructor() ERC721("Individual MetaProfile", "IMP") {
    }

    /**
     * @dev Everyone can mint his/her own profile nft.
     */
    function mint(bool isSubleaseAllowed) public {
        require(balanceOf(_msgSender()) < 1, "MetaProfile: one address can only mint one profile NFT");
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(_msgSender(), tokenId);
        _subleaseAllowed[tokenId] = isSubleaseAllowed;
    }

    /**
     * @dev Everyone has to remint his/her own profile NFT, after the profile has been updated.
     */
    function remint(uint256 tokenId, bool isSubleaseAllowed) public {
        burn(tokenId);
        mint(isSubleaseAllowed);
    }
    
    /**
     * @dev Everyone can burn his/her own profile NFT
     */
    function burn(uint256 tokenId) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        require(_leaseExpires[tokenId] < block.timestamp, "Lease: there is a ongoing lease at least");
        _burn(tokenId);
        // not do delete action actually so as to save gas fee
        // delete _subleaseAllowed[tokenId];
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev lease the NFT to the leasee, throws if unauthorized to lease (not the token owner)
     * or there is a ongoing lease
     * @param tokenId The NFT
     * @param leasee The leasee of the NFT
     * @param expires UNIX timestamp, The leasee could use the NFT before expires
     */
    function lease(uint256 tokenId, address leasee, uint256 expires) external {
        require(expires > block.timestamp, "Lease: expires must greater than now");
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        
        _setLastLeaseExpires(tokenId, expires);

        uint256 currentExpires = _lease[tokenId][leasee];
        if (currentExpires < expires) {
            _lease[tokenId][leasee] = expires;
        }
        
        emit Lease(tokenId, leasee, expires);
    }

    /**
     * @dev Returns whether the NFT is allowed to sublease
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function isAllowedForSublease(uint256 tokenId) public view returns (bool) {
        require(_exists(tokenId), "ERC721: invalid token ID");
        return _subleaseAllowed[tokenId];
    }

    /**
     * @dev sublease the NFT to the next leasee, throws if unauthorized to lease (only the current leasee)
     * @param tokenId The NFT
     * @param oldLeasee The current leasee of the NFT
     * @param newLeasee The next leasee of the NFT after subleasing
     */
    function sublease(uint256 tokenId, address oldLeasee, address newLeasee) external {
        require(_isApprovedAndLeasee(oldLeasee, tokenId), "Lease: caller is not the current leasee");

        _lease[tokenId][newLeasee] = _lease[tokenId][oldLeasee];
        delete _lease[tokenId][oldLeasee];

        emit Sublease(tokenId, oldLeasee, newLeasee, _lease[tokenId][newLeasee]);
    }

    /**
     * @dev Returns whether `Leasee` is allowed to sublease the NFT.
     */
    function _isApprovedAndLeasee(address Leasee, uint256 tokenId) internal view virtual returns (bool) {
        address sender = _msgSender();
        address owner = ERC721.ownerOf(tokenId);
        return (
            _subleaseAllowed[tokenId]
            && _lease[tokenId][Leasee] > block.timestamp
            && (
                sender == Leasee
                || isApprovedForAll(owner, sender) 
                || getApproved(tokenId) == sender
            )
        );
    }

    /**
     * @dev Get the leasee expires of an NFT, the zero value indicates that there is no ongoing lease of the leasee
     * @param tokenId The NFT
     * @param leasee The leasee of the NFT
     * @return expires The leasee expires for this NFT
     */
    function leaseExpiresOf(uint256 tokenId, address leasee) external view returns(uint256) {
        require(_exists(tokenId), "ERC721: invalid token ID");
        return _lease[tokenId][leasee];
    }

    /**
     * @dev Get the last expires of an NFT among all the leases, the zero value indicates that there is no ongoing lease
     * @param tokenId The NFT
     * @return expires the last lease time of the token.
     */
    function leaseExpiresOf(uint256 tokenId) external view returns (uint256) {
        require(_exists(tokenId), "ERC721: invalid token ID");
        return _leaseExpires[tokenId];
    }
    
    /**
     * @dev Set the last lease expires of the NFT.
     */
    function _setLastLeaseExpires(uint256 tokenId, uint256 expires) internal {
        uint256 currentLastLeaseTime = _leaseExpires[tokenId];
        if (expires > currentLastLeaseTime) {
          _leaseExpires[tokenId] = expires;
        }
    }

    /**
     * @dev overrides Base URI for computing {tokenURI}.
     */
    function _baseURI() internal view virtual override(ERC721) returns (string memory) {
        return "https://metaid.io/";
    }
}