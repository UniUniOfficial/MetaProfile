// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";


/**
 * @dev compose the element NFTs into the profile
 */
abstract contract Component is ERC721, ERC721Enumerable, EIP712, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    
    address public immutable profile;

    uint256 public immutable MAX_SUPPLY;

    // Mapping from token ID to the current owner
    mapping(uint256 => address) private _componentUsed;

    constructor(string memory name, string memory symbol, address profileAddress, uint256 max_supply)
        ERC721(name, symbol)
        EIP712(name, "1.0.0") {
            MAX_SUPPLY = max_supply;
            profile = profileAddress;
    }

    function mint(address to) public onlyOwner {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(to, tokenId);
    }

    function airdrop(address to, uint256 tokenId, bytes calldata signature) external {
        require(_verify(_hash(to, tokenId), signature), "Invalid signature");
        _safeMint(to, tokenId);
    }

    function _hash(address to, uint256 tokenId) internal view returns (bytes32) {
        return _hashTypedDataV4(keccak256(abi.encode(
            keccak256("Airdrop(address account, uint256 tokenId)"),
            tokenId,
            to
        )));
    }

    function _verify(bytes32 digest, bytes memory signature) internal view returns (bool) {
        return owner() == ECDSA.recover(digest, signature);
    }

    /**
     * @dev Throws if called by any account other than the profile contract.
     */
    modifier onlyProfile() {
        require(profile == _msgSender(), "Compose: caller is not the profile contract");
        _;
    }

    function compose(uint256 tokenId) external onlyProfile {
        address account = tx.origin;
        require(account == super.ownerOf(tokenId), "Compose: transaction is not signed by the token owner");

        super._burn(tokenId);
        _componentUsed[tokenId] = account;
    }

    function uncompose(uint256 tokenId) external onlyProfile returns (uint256) {
        address account = tx.origin;
        require(_componentUsed[tokenId] != address(0), "Uncompose: the user does not own the token");
        
        delete _componentUsed[tokenId];
        super._safeMint(account, tokenId);
        return tokenId;
    }

    /**
     * @dev Override the logic that limit the NFTs totally to max supply
     */
    function _safeMint(address to, uint256 tokenId) internal override virtual {
        require(tokenId <= MAX_SUPPLY, "Genesis Avatars are reached to max supply limit");
        super._safeMint(to, tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

}