// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";


/*
 * ERC4907 only applies for whole lease pattern
 * But digital crypto nft assets can be leased by many copies of their own
 * So this is a improved interface for multi-copy lease, 
 * and is compatible with with ERC721
 */
contract ERC721Lease is ERC721, ERC721Enumerable {

    // Mapping from token ID to the last expires of all the leases
    mapping(uint256 => uint256) private _lease_expires;

    // Mapping from token ID to the expires of the lease
    mapping(uint256 => mapping(address => uint256)) private _lease;

    /**
     * @notice Emitted when the lease of a NFT happened
     */
    event Lease(uint256 indexed tokenId, address indexed leasee, uint256 expires);

    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {
    }

    /**
     * @notice set the leasee and expires of a NFT
     * @dev Throws if unauthorized to lease (the token owner or the current leasee)
     * or there is a ongoing lease
     * @param tokenId The NFT to get the leasee expires for
     * @param leasee The leasee of the NFT
     * @param expires UNIX timestamp, The leasee could use the NFT before expires
     */
    function lease(uint256 tokenId, address leasee, uint256 expires) external {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        require(expires > block.timestamp, "Lease: expires must greater than now");
        
        _setLastLeaseExpires(tokenId, expires);

        uint256 current_expires = _lease[tokenId][leasee];
        if (current_expires < expires) {
            _lease[tokenId][leasee] = expires;
        }
        
        emit Lease(tokenId, leasee, expires);
    }

    /**
     * @dev Get the leasee expires of an NFT, the zero value indicates that there is no ongoing lease of the leasee
     * @param tokenId The NFT to get the leasee expires for
     * @param leasee The leasee of the NFT
     * @return expires The leasee expires for this NFT
     */
    function leaseExpiresOf(uint256 tokenId, address leasee) external view returns(uint256) {
        return _lease[tokenId][leasee];
    }

    /**
     * @dev Get the last expires of an NFT among all the leases, the zero value indicates that there is no ongoing lease
     * @param tokenId The NFT to get the leasee expires for
     * @return expires the last lease time of the token.
     */
    function leaseExpiresOf(uint256 tokenId) external view returns (uint256) {
        return _lease_expires[tokenId];
    }
    
    /**
     * @dev Set the last lease expires of the token.
     */
    function _setLastLeaseExpires(uint256 tokenId, uint256 expires) internal {
        uint256 current_last_lease_time = _lease_expires[tokenId];
        if (expires > current_last_lease_time) {
          _lease_expires[tokenId] = expires;
        }
    }

    /**
     * @dev Everyone can burn his/her own profile nft
     */
    function burn(uint256 tokenId) public virtual {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        require(_lease_expires[tokenId] < block.timestamp, "Lease: there is a ongoing lease at least");
        _burn(tokenId);
    }

    /**
     * @dev overrides the tranfer logic that the token is not allowed to transfer
     * if there is a ongoing lease
     */
    function _transfer(address from, address to, uint256 tokenId) internal virtual override(ERC721) {
        require(_lease_expires[tokenId] < block.timestamp, "Lease: there is a ongoing lease at least");
        return super._transfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

}