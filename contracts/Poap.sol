// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "./PoapRoles.sol";
import "./PoapEvent.sol";

contract Poap is
    Initializable,
    ERC721EnumerableUpgradeable,
    PausableUpgradeable,
    PoapEvent,
    PoapRoles
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using StringsUpgradeable for uint256;

    event EventToken(uint256 eventId, uint256 tokenId);

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
        _addEventCreator(lastEventId.current(), msg.sender);

        return lastEventId.current();
    }

    function authorize(uint256 eventId) public {
        _requireAdmin();
        _requireEventExist(eventId);

        _authorize(eventId);
    }

    function unauthorize(uint256 eventId) public {
        _requireAdmin();
        _requireEventExist(eventId);

        _unauthorize(eventId);
    }

    /**
     * @dev Function to view poap's uri
     * @param tokenId poap's token id.
     * @return string poap's uri
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        _requireMinted(tokenId);

        return eventMetaURI(tokenEvent(tokenId));
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
    function mintToken(uint256 eventId, address to)
        external
        whenNotPaused
        returns (bool)
    {
        _requireEventMinter(eventId);
        _requireEventExist(eventId);
        _requireUserNotExist(eventId, to);

        lastId.increment();
        return _mintToken(eventId, lastId.current(), to);
    }

    /**
     * @dev Function to mint tokens
     * @param eventId EventId for the new token
     * @param to The address that will receive the minted tokens.
     * @return A boolean that indicates if the operation was successful.
     */
    function mintEventToManyUsers(uint256 eventId, address[] calldata to)
        external
        whenNotPaused
        returns (bool)
    {
        _requireEventMinter(eventId);
        _requireEventExist(eventId);

        for (uint256 i = 0; i < to.length; ++i) {
            _requireUserNotExist(eventId, to[i]);
            lastId.increment();
            _mintToken(eventId, lastId.current(), to[i]);
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
        uint256 eventId = tokenEvent(tokenId);
        address to = ownerOf(tokenId);
        _removeEventUser(tokenEvent(tokenId), ownerOf(tokenId));
        _removeTokenEvent(tokenId);
        if (isEventMinter(eventId, to)) {
            if (isEventCreator(eventId, to)) {
                _changeEventCreator(eventId, address(0));
            } else {
                _removeEventMinter(eventId, to);
            }
        }
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
        address to
    ) internal returns (bool) {
        _mint(to, tokenId);
        _addEventUser(eventId, to);
        _addTokenEvent(eventId, tokenId);
        emit EventToken(eventId, tokenId);
        return true;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override whenNotPaused {
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
            uint256 eventId = tokenEvent(tokenId);
            _requireUserNotExist(eventId, to);

            _removeEventUser(eventId, from);
            _addEventUser(eventId, to);

            if (isEventMinter(eventId, from)) {
                if (isEventCreator(eventId, from)) {
                    _changeEventCreator(eventId, to);
                } else {
                    _removeEventMinter(eventId, from);
                    _addEventMinter(eventId, to);
                }
            }
        }
    }

    function _beforeAddEventMinter(uint256 eventId, address account)
        internal
        override
    {
        // A event minter must have the event poap
        if (!eventHasUser(eventId, account)) {
            lastId.increment();
            _mintToken(eventId, lastId.current(), account);
        }
    }
}
