// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "./PoapRoles.sol";
import "./PoapEvent.sol";

contract Poap is
    Initializable,
    ERC721EnumerableUpgradeable,
    ERC721URIStorageUpgradeable,
    PausableUpgradeable,
    PoapEvent,
    PoapRoles
{
    using CountersUpgradeable for CountersUpgradeable.Counter;

    event EventToken(uint256 eventId, uint256 tokenId);

    // Base token URI
    string private _bbaseURI;

    // Last Used id (used to generate new ids)
    CountersUpgradeable.Counter private lastId;
    CountersUpgradeable.Counter private lastEventId;

    /**
     * @dev Function to create event. you have to retrieve event id from EventAdded log
     * @param eventURI event meta uri
     * @return uint256 the event id
     */
    function createEvent(string calldata eventURI)
        external
        whenNotPaused
        returns (uint256)
    {
        lastEventId.increment();
        _createEvent(lastEventId.current(), eventURI);
        _addEventMinter(lastEventId.current(), msg.sender);

        return lastEventId.current();
    }

    /**
     * @dev Function to view poap's uri
     * @param tokenId poap's token id.
     * @return string poap's uri
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function setBaseURI(string calldata __baseURI) external {
        _requireAdmin();
        _bbaseURI = __baseURI;
    }

    function eventOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256)
    {
        return tokenEvent(tokenOfOwnerByIndex(owner, index));
    }

    /**
     * @dev Function to mint tokens
     * @param eventId EventId for the new token
     * @param to The address that will receive the minted tokens.
     * @return A boolean that indicates if the operation was successful.
     */
    function mintToken(
        uint256 eventId,
        string calldata _tokenURI,
        address to
    ) external returns (bool) {
        _requireEventMinter(eventId);
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
        string[] calldata _tokenURI,
        address[] calldata to
    ) external returns (bool) {
        require(
            _tokenURI.length == to.length,
            "Poap: urls need the same length with users"
        );
        _requireEventMinter(eventId);
        for (uint256 i = 0; i < to.length; ++i) {
            lastId.increment();
            _mintToken(eventId, lastId.current(), _tokenURI[i], to[i]);
        }
        return true;
    }

    /**
     * @dev Burns a specific ERC721 token.
     * @param tokenId uint256 id of the ERC721 token to be burned.
     */
    function burn(uint256 tokenId) external whenNotPaused {
        require(
            _isApprovedOrOwner(msg.sender, tokenId) || isAdmin(msg.sender),
            "Poap: no access to burn"
        );
        _removeEventUser(tokenEvent(tokenId), ownerOf(tokenId));
        _removeTokenEvent(tokenId);
        _burn(tokenId);
    }

    function pause() public {
        _requireAdmin();
        _pause();
    }

    function unpause() public {
        _requireAdmin();
        _unpause();
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
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

    function __POAP_init(
        string calldata __name,
        string calldata __symbol,
        string calldata __baseURI,
        address[] calldata admins
    ) public initializer {
        ERC721Upgradeable.__ERC721_init(__name, __symbol);
        PoapRoles.__ROLE_init(msg.sender);
        PoapEvent.__EVENT_init();
        PausableUpgradeable.__Pausable_init();
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
        string calldata _tokenURI,
        address to
    ) internal whenNotPaused returns (bool) {
        _mint(to, tokenId);
        _setTokenURI(tokenId, _tokenURI);
        _addEventUser(eventId, to);
        _addTokenEvent(eventId, tokenId);
        emit EventToken(eventId, tokenId);
        return true;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    )
        internal
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        whenNotPaused
    {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            // mint, do nothing
            return;
        }
        if (to == address(0)) {
            // burn, do nothing
            return;
        }
        if (from != to) {
            // real transfer
            require(
                !eventHasUser(tokenEvent(tokenId), to),
                "Poap: user already have this event"
            );
            _removeEventUser(tokenEvent(tokenId), from);
            _addEventUser(tokenEvent(tokenId), to);
        }
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
