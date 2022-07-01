// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./nft/ERC721Lease.sol";


contract MetaProfile is ERC721Lease, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    /**
     * Approve the exchange contract to handle tokens
     * in order to save gas fee
     */
    address private _exchange;

    constructor() ERC721Lease("MetaProfileID", "MPID") {
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
     * @dev Throws if called by any account other than the rental exchange contract.
     */
    modifier onlyExchange() {
        require(exchange() == _msgSender(), "Rental Exchange: caller is not the current rental exchange contract");
        _;
    }

    /**
     * @dev Returns the address of the exchange contract.
     */
    function exchange() public view returns (address) {
        return _exchange;
    }

    /**
     * @dev Change the rental exchange contract.
     */
    function setExchange(address newExchange) public onlyOwner {
        require(newExchange != address(0), "Rental Exchange: new rental exchange is the zero address");
        _exchange = newExchange;
    }
}
