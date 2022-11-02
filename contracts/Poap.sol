// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "./PoapRoles.sol";
import "./PoapEvent.sol";
import "./PoapPausable.sol";

// Desired Features
// - Add Event
// - Add Event Organizer
// - Mint token for an event
// - Batch Mint
// - Burn Tokens (only admin?)
// - Pause contract (only admin)
// - ERC721 full interface (base, metadata, enumerable)

contract Poap is
    Initializable,
    ERC721EnumerableUpgradeable,
    ERC721URIStorageUpgradeable,
    PoapEvent,
    PoapRoles,
    PoapPausable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;

    event EventToken(uint256 eventId, uint256 tokenId);

    // Base token URI
    string private _bbaseURI;

    // Last Used id (used to generate new ids)
    CountersUpgradeable.Counter private lastId;
    CountersUpgradeable.Counter private lastEventId;

    // EventId for each token

    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    function createEvent(string memory eventName) external returns (uint256) {
        lastEventId.increment();
        _createEvent(lastEventId.current(), eventName);
        _addEventMinter(lastEventId.current(), msg.sender);

        return lastEventId.current();
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        tokenExist(tokenId)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setBaseURI(string memory __baseURI) external onlyAdmin {
        _bbaseURI = __baseURI;
    }

    /**
     * @dev Gets the token ID at a given index of the tokens list of the requested owner
     * @param owner address owning the tokens list to be accessed
     * @param index uint256 representing the index to be accessed of the requested tokens list
     * @return tokenId uint256 token ID at the given index of the tokens list owned by the requested address
     * @return eventId uint256 token ID at the given index of the tokens list owned by the requested address
     */
    function tokenDetailsOfOwnerByIndex(address owner, uint256 index)
        public
        view
        returns (uint256 tokenId, uint256 eventId)
    {
        tokenId = tokenOfOwnerByIndex(owner, index);
        eventId = tokenEvent(tokenId);
    }

    function approve(address to, uint256 tokenId)
        public
        override
        whenNotPaused
    {
        super.approve(to, tokenId);
    }

    function setApprovalForAll(address to, bool approved)
        public
        override
        whenNotPaused
    {
        super.setApprovalForAll(to, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override whenNotPaused {
        super.transferFrom(from, to, tokenId);
    }

    /**
     * @dev Function to mint tokens
     * @param eventId EventId for the new token
     * @param to The address that will receive the minted tokens.
     * @return A boolean that indicates if the operation was successful.
     */
    function mintToken(
        uint256 eventId,
        string memory _tokenURI,
        address to
    ) external whenNotPaused onlyEventMinter(eventId) returns (bool) {
        lastId.increment();
        return _mintToken(eventId, lastId.current(), _tokenURI, to);
    }

    /**
     * @dev Function to mint tokens
     * @param eventId EventId for the new token
     * @param to The address that will receive the minted tokens.
     * @return A boolean that indicates if the operation was successful.
     */
    function mintEventToManyUsers(
        uint256 eventId,
        string[] memory _tokenURI,
        address[] memory to
    ) external whenNotPaused onlyEventMinter(eventId) returns (bool) {
        require(
            _tokenURI.length == to.length,
            "Poap: token urls should have the same length with Users"
        );
        for (uint256 i = 0; i < to.length; ++i) {
            lastId.increment();
            _mintToken(eventId, lastId.current(), _tokenURI[i], to[i]);
        }
        return true;
    }

    /**
     * @dev Function to mint tokens
     * @param eventIds EventIds to assing to user
     * @param to The address that will receive the minted tokens.
     * @return A boolean that indicates if the operation was successful.
     */
    function mintUserToManyEvents(
        uint256[] memory eventIds,
        string[] memory _tokenURI,
        address to
    ) external whenNotPaused onlyAdmin returns (bool) {
        require(
            _tokenURI.length == eventIds.length,
            "Poap: token urls should have the same length with events"
        );
        for (uint256 i = 0; i < eventIds.length; ++i) {
            lastId.increment();
            _mintToken(eventIds[i], lastId.current(), _tokenURI[i], to);
        }
        return true;
    }

    /**
     * @dev Burns a specific ERC721 token.
     * @param tokenId uint256 id of the ERC721 token to be burned.
     */
    function burn(uint256 tokenId) external {
        require(_isApprovedOrOwner(msg.sender, tokenId) || isAdmin(msg.sender));
        removeEventUser(tokenEvent(tokenId), ownerOf(tokenId));
        removeTokenEvent(tokenId);
        _burn(tokenId);
    }

    function __POAP_init(
        string memory __name,
        string memory __symbol,
        string memory __baseURI,
        address[] memory admins
    ) public initializer {
        ERC721Upgradeable.__ERC721_init(__name, __symbol);
        PoapRoles.__ROLE_init(msg.sender);
        PoapPausable.__PAUSABLE_init();
        PoapEvent.__EVENT_init();

        // Add the requested admins
        for (uint256 i = 0; i < admins.length; ++i) {
            _addAdmin(admins[i]);
        }

        _bbaseURI = __baseURI;
    }

    /**
     * @dev Function to mint tokens
     * @param eventId EventId for the new token
     * @param tokenId The token id to mint.
     * @param to The address that will receive the minted tokens.
     * @return A boolean that indicates if the operation was successful.
     */
    function _mintToken(
        uint256 eventId,
        uint256 tokenId,
        string memory _tokenURI,
        address to
    ) internal returns (bool) {
        _mint(to, tokenId);
        _setTokenURI(tokenId, _tokenURI);
        addTokenEvent(eventId, tokenId);
        addEventUser(eventId, to);
        emit EventToken(eventId, tokenId);
        return true;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    {
        super._burn(tokenId);
    }

    function _baseURI() internal view override returns (string memory) {
        return _bbaseURI;
    }
}
