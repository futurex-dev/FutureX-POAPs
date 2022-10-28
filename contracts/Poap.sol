// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "./PoapRoles.sol";
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
    PoapRoles,
    PoapPausable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;

    event EventToken(uint256 eventId, uint256 tokenId);

    // Base token URI
    string private _bbaseURI;

    // Last Used id (used to generate new ids)
    CountersUpgradeable.Counter private lastId;

    // EventId for each token
    mapping(uint256 => uint256) private _tokenEvent;

    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    modifier eventOnce(uint256 eventId, address to) {
        require(isAdmin(msg.sender));
        uint256 balances = ERC721Upgradeable.balanceOf(to);
        uint256 tokenId;
        for (uint256 i = 0; i < balances; ++i) {
            tokenId = tokenOfOwnerByIndex(to, i);
            require(
                eventId != tokenEvent(tokenId),
                "Poap: already assigned the event"
            );
        }
        _;
    }

    function tokenEvent(uint256 tokenId) public view returns (uint256) {
        return _tokenEvent[tokenId];
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

    /**
     * @dev Gets the token uri
     * @return string representing the token uri
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        uint eventId = _tokenEvent[tokenId];
        return
            _strConcat(
                _bbaseURI,
                _uint2str(eventId),
                "/",
                _uint2str(tokenId),
                ""
            );
    }

    function setBaseURI(string memory baseURI) public onlyAdmin whenNotPaused {
        _bbaseURI = baseURI;
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
    function mintToken(uint256 eventId, address to)
        public
        whenNotPaused
        onlyEventMinter(eventId)
        returns (bool)
    {
        lastId.increment();
        return _mintToken(eventId, lastId.current(), to);
    }

    /**
     * @dev Function to mint tokens
     * @param eventId EventId for the new token
     * @param to The address that will receive the minted tokens.
     * @return A boolean that indicates if the operation was successful.
     */
    function mintEventToManyUsers(uint256 eventId, address[] memory to)
        public
        whenNotPaused
        onlyEventMinter(eventId)
        returns (bool)
    {
        for (uint256 i = 0; i < to.length; ++i) {
            lastId.increment();
            _mintToken(eventId, lastId.current(), to[i]);
        }
        return true;
    }

    /**
     * @dev Function to mint tokens
     * @param eventIds EventIds to assing to user
     * @param to The address that will receive the minted tokens.
     * @return A boolean that indicates if the operation was successful.
     */
    function mintUserToManyEvents(uint256[] memory eventIds, address to)
        public
        whenNotPaused
        onlyAdmin
        returns (bool)
    {
        for (uint256 i = 0; i < eventIds.length; ++i) {
            lastId.increment();
            _mintToken(eventIds[i], lastId.current(), to);
        }
        return true;
    }

    /**
     * @dev Burns a specific ERC721 token.
     * @param tokenId uint256 id of the ERC721 token to be burned.
     */
    function burn(uint256 tokenId) public {
        require(_isApprovedOrOwner(msg.sender, tokenId) || isAdmin(msg.sender));
        _burn(tokenId);
    }

    function __POAP_init(
        string memory __name,
        string memory __symbol,
        string memory __baseURI,
        address[] memory admins
    ) public initializer {
        ERC721Upgradeable.__ERC721_init(__name, __symbol);
        // __ERC721_init(__name, __symbol);
        PoapRoles.initialize(msg.sender);
        PoapPausable.initialize();

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
        address to
    ) internal eventOnce(eventId, to) returns (bool) {
        _mint(to, tokenId);
        _tokenEvent[tokenId] = eventId;
        emit EventToken(eventId, tokenId);
        return true;
    }

    /**
     * @dev Function to convert uint to string
     * Taken from https://github.com/oraclize/ethereum-api/blob/master/oraclizeAPI_0.5.sol
     */
    function _uint2str(uint _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = bytes1(uint8(48 + (_i % 10)));
            _i /= 10;
        }
        return string(bstr);
    }

    /**
     * @dev Function to concat strings
     * Taken from https://github.com/oraclize/ethereum-api/blob/master/oraclizeAPI_0.5.sol
     */
    function _strConcat(
        string memory _a,
        string memory _b,
        string memory _c,
        string memory _d,
        string memory _e
    ) internal pure returns (string memory _concatenatedString) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        bytes memory _bd = bytes(_d);
        bytes memory _be = bytes(_e);
        string memory abcde = new string(
            _ba.length + _bb.length + _bc.length + _bd.length + _be.length
        );
        bytes memory babcde = bytes(abcde);
        uint k = 0;
        uint i = 0;
        for (i = 0; i < _ba.length; i++) {
            babcde[k++] = _ba[i];
        }
        for (i = 0; i < _bb.length; i++) {
            babcde[k++] = _bb[i];
        }
        for (i = 0; i < _bc.length; i++) {
            babcde[k++] = _bc[i];
        }
        for (i = 0; i < _bd.length; i++) {
            babcde[k++] = _bd[i];
        }
        for (i = 0; i < _be.length; i++) {
            babcde[k++] = _be[i];
        }
        return string(babcde);
    }

    function removeAdmin(address account) public onlyAdmin {
        _removeAdmin(account);
    }
}
