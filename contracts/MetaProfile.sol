// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";


contract MetaProfile is ERC721, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    /**
     * Approve the rental exchange to update the rental info
     * in order to save gas fee
     */
    address private _rental_exchange;

    // Mapping from token ID to the last rental time
    mapping(uint256 => uint256) private _rental_time;

    constructor() ERC721("MetaProfileID", "MPID") {
    }

    /**
     * @dev Everyone can mint its own profile nft.
     */
    function mint() public {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(_msgSender(), tokenId);
    }

    /**
     * @dev Everyone has to remint its own profile nfts, when the profile has been updated.
     */
    function remint(uint256 tokenId) public {
        burn(tokenId);
        mint();
    }

    /**
     * @dev Returns the rental time of the token.
     */
    function rentalTimeOf(uint256 tokenId) public view returns (uint256)  {
        return _rental_time[tokenId];
    }

    /**
     * @dev Set the rental time of the token.
     */
    function setRentalTime(uint256 tokenId, uint rentalTime) public {
        uint256 current_rental_time = _rental_time[tokenId];
        if (rentalTime > current_rental_time) {
          _rental_time[tokenId] = current_rental_time;
        }
    }

    /**
     * @dev Throws if called by any account other than the rental exchange contract.
     */
    modifier onlyRentalExchange() {
        require(rentalExchange() == _msgSender(), "Rental Exchange: caller is not the current rental exchange contract");
        _;
    }

    /**
     * @dev Returns the address of the rental exchange contract.
     */
    function rentalExchange() public view returns (address) {
        return _rental_exchange;
    }

    /**
     * @dev Change the rental exchange contract.
     */
    function setRentalExchange(address newRentalExchange) public onlyOwner {
        require(newRentalExchange != address(0), "Rental Exchange: new rental exchange is the zero address");
        _rental_exchange = newRentalExchange;
    }
}
