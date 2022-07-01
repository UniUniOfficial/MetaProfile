// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";


/*
 * IERC4907 only apply for whole rental
 * But digital crypto nft assets can be rented by many copies of their own
 * So this is a improved interface for multi-copy rental, 
 * and is compatible with with ERC721
 */
contract ERC721Rental is ERC721 {

    // Mapping from token ID to the last expires of the rentals
    mapping(uint256 => uint256) private _rental_expires;

    // Mapping from token ID to rentals
    mapping(uint256 => mapping(address => uint256)) private _rental;

    /// @notice Emitted when the rental of a NFT happened
    event Rental(uint256 indexed tokenId, address indexed rentee, uint256 expires);

    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {
    }

    /// @notice set the rentee and expires of a NFT
    /// @dev The zero address indicates there is no rentee
    /// Throws if `tokenId` is not valid NFT
    /// or unauthorized to rent (the token owner or the authorized proxy)
    /// or there is a ongoing rental
    /// @param rentee The rentee of the NFT
    /// @param expires UNIX timestamp, The rentee could use the NFT before expires
    function safeRent(uint256 tokenId, address rentee, uint256 expires) external {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        require(expires > block.timestamp, "Rental: expires must greater than now");
        require(_rental[tokenId][rentee] < block.timestamp, "Rental: there is an ongoing rental");

        _setLastRentalExpires(tokenId, expires);
        _rental[tokenId][rentee] = expires;
        
        emit Rental(tokenId, rentee, expires);
    }

    /// @notice Get the rentee expires of an NFT
    /// @dev The zero value indicates that there is no ongoing rental of the rentee
    /// @param tokenId The NFT to get the user expires for
    /// @param rentee The rentee of the NFT
    /// @return expires The rentee expires for this NFT
    function rentalExpires(uint256 tokenId, address rentee) external view returns(uint256) {
        return _rental[tokenId][rentee];
    }
    /**
     * @notice Get the last expires of an NFT among all the rentals
     * @dev The zero value indicates that there is no ongoing rental
     * @param tokenId The NFT to get the user expires for
     * @return expires the last rental time of the token.
     */
    function rentalExpires(uint256 tokenId) external view returns (uint256) {
        return _rental_expires[tokenId];
    }
    
    /**
     * @dev Set the last rental expires of the token.
     */
    function _setLastRentalExpires(uint256 tokenId, uint256 expires) internal {
        uint256 current_last_rental_time = _rental_expires[tokenId];
        if (expires > current_last_rental_time) {
          _rental_expires[tokenId] = expires;
        }
    }

    /**
     * @dev overrides the tranfer logic that the token is not allowed to transfer
     * if there is a ongoing rental
     */
    function _transfer(address from, address to, uint256 tokenId) internal virtual override(ERC721) {
        require(_rental_expires[tokenId] < block.timestamp, "Rental: there is a ongoing rental at least");
        return super._transfer(from, to, tokenId);
    }

    /**
     * @dev overrides the burn logic that the token is not allowed to burn
     * if there is a ongoing rental
     */
    function _burn(uint256 tokenId) internal virtual override(ERC721) {
        require(_rental_expires[tokenId] < block.timestamp, "Rental: there is a ongoing rental at least");
        return super._burn(tokenId);
    }
}