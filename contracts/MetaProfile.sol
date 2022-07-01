// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./nft/ERC721Rental.sol";


contract MetaProfile is ERC721Rental, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    /**
     * Approve the rental exchange to update the rental info
     * in order to save gas fee
     */
    address private _rental_exchange;

    constructor() ERC721Rental("MetaProfileID", "MPID") {
    }

    /**
     * @dev Everyone can mint his/her own profile nft.
     */
    function mint() public {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(_msgSender(), tokenId);
    }

    /**
     * @dev Everyone has to remint his/her own profile nft, after the profile has been updated.
     */
    function remint(uint256 tokenId) public {
        burn(tokenId);
        mint();
    }

    /**
     * @dev Everyone can burn his/her own profile nft
     */
    function burn(uint256 tokenId) public virtual {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _burn(tokenId);
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
