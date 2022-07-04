// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";


/*
 * ERC4907 only applies for whole lease pattern
 * But digital crypto nft assets can be leased by many copies of their own
 * So this is a improved interface for multi-copy lease, 
 * and is compatible with with ERC721
 */
contract MetaProfile is ERC721, ERC721Enumerable, Ownable {
    // Generate Token ID
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

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

    /**
     * Approve the exchange contract to handle NFTs
     * in order to save gas fee
     */
    address private _exchange;

    constructor() ERC721("MetaProfileID", "MPID") {
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
     * @dev Everyone has to remint his/her own profile NFT, after the profile has been updated.
     */
    function remint(uint256 tokenId) public {
        burn(tokenId);
        mint();
    }
    
    /**
     * @dev Everyone can burn his/her own profile NFT
     */
    function burn(uint256 tokenId) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        require(_leaseExpires[tokenId] < block.timestamp, "Lease: there is a ongoing lease at least");
        _burn(tokenId);
    }

    /**
     * @dev overrides the tranfer logic that the token is not allowed to transfer
     * if there is a ongoing lease
     */
    function _transfer(address from, address to, uint256 tokenId) internal virtual override(ERC721) {
        require(_leaseExpires[tokenId] < block.timestamp, "Lease: there is a ongoing lease at least");
        return super._transfer(from, to, tokenId);
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

        uint256 current_expires = _lease[tokenId][leasee];
        if (current_expires < expires) {
            _lease[tokenId][leasee] = expires;
        }
        
        emit Lease(tokenId, leasee, expires);
    }

    /**
     * @dev sublease the NFT to the next leasee, throws if unauthorized to lease (only the current leasee)
     * @param tokenId The NFT
     * @param oldLeasee The current leasee of the NFT
     * @param newLeasee The next leasee of the NFT after subleasing
     */
    function sublease(uint256 tokenId, address oldLeasee, address newLeasee) external {
        require(_isApprovedOrLeasee(oldLeasee, tokenId), "Lease: caller is not the current leasee");

        _lease[tokenId][newLeasee] = _lease[tokenId][oldLeasee];
        _lease[tokenId][oldLeasee] = 0;

        emit Sublease(tokenId, oldLeasee, newLeasee, _lease[tokenId][newLeasee]);
    }

    /**
     * @dev overrides approval logic, permit preset the exchange contract to handle the NFT
     */
    function _isApprovedOrOwner(address sender, uint256 tokenId) internal view override(ERC721) returns (bool) {
        return super._isApprovedOrOwner(sender, tokenId) || sender == _exchange;
    }

    /**
     * @dev Returns whether `Leasee` is allowed to sublease the NFT.
     */
    function _isApprovedOrLeasee(address Leasee, uint256 tokenId) internal view virtual returns (bool) {
        address sender = _msgSender();
        address owner = ERC721.ownerOf(tokenId);
        return (
            (
                sender == Leasee
                || isApprovedForAll(owner, sender) 
                || getApproved(tokenId) == sender
                || sender == _exchange
            )
            && _lease[tokenId][Leasee] > block.timestamp
        );
    }

    /**
     * @dev Get the leasee expires of an NFT, the zero value indicates that there is no ongoing lease of the leasee
     * @param tokenId The NFT
     * @param leasee The leasee of the NFT
     * @return expires The leasee expires for this NFT
     */
    function leaseExpiresOf(uint256 tokenId, address leasee) external view returns(uint256) {
        return _lease[tokenId][leasee];
    }

    /**
     * @dev Get the last expires of an NFT among all the leases, the zero value indicates that there is no ongoing lease
     * @param tokenId The NFT
     * @return expires the last lease time of the token.
     */
    function leaseExpiresOf(uint256 tokenId) external view returns (uint256) {
        return _leaseExpires[tokenId];
    }
    
    /**
     * @dev Set the last lease expires of the token.
     */
    function _setLastLeaseExpires(uint256 tokenId, uint256 expires) internal {
        uint256 currentLastLeaseTime = _leaseExpires[tokenId];
        if (expires > currentLastLeaseTime) {
          _leaseExpires[tokenId] = expires;
        }
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
