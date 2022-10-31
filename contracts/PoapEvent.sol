// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./Roles.sol";

/**
 * @title PoapEvent
 * @dev Library for managing events and its users
 */
contract PoapEvent is Initializable {
    struct Event {
        string name;
        mapping(address => bool) reverse_index;
    }

    event EventAdded(
        uint256 indexed eventId,
        address indexed creator,
        string eventName
    );

    mapping(uint256 => Event) private _event_infos;
    mapping(uint256 => uint256) private _token_events;
    mapping(uint256 => bool) private _event_exist;

    modifier eventExist(uint256 eventId) {
        require(_event_exist[eventId], "Poap: event not exists");
        _;
    }

    modifier eventNotExist(uint256 eventId) {
        require(!_event_exist[eventId], "Poap: event already existed");
        _;
    }

    modifier userNotExist(uint256 eventId, address user) {
        require(
            !_event_infos[eventId].reverse_index[user],
            "Poap: already assigned the event"
        );
        _;
    }

    modifier tokenExist(uint256 token) {
        require(_token_events[token] != uint256(0), "Poap: token wasn't exist");
        _;
    }

    function __EVENT_init() public initializer {}

    function _createEvent(uint256 eventId, string memory eventName) internal {
        require(!_event_exist[eventId], "Poap: event already existed");
        _event_exist[eventId] = true;
        _event_infos[eventId].name = eventName;
        emit EventAdded(eventId, msg.sender, eventName);
    }

    function addEventUser(uint256 eventId, address user)
        internal
        eventExist(eventId)
        userNotExist(eventId, user)
    {
        _event_infos[eventId].reverse_index[user] = true;
    }

    function removeEventUser(uint256 eventId, address user)
        internal
        eventExist(eventId)
    {
        require(
            _event_infos[eventId].reverse_index[user],
            "Poap: user didn't exist"
        );
        _event_infos[eventId].reverse_index[user] = false;
    }

    function eventHasUser(uint256 eventId, address user)
        public
        view
        eventExist(eventId)
        returns (bool)
    {
        return _event_infos[eventId].reverse_index[user];
    }

    function eventMetaName(uint256 eventId)
        public
        view
        eventExist(eventId)
        returns (string memory)
    {
        return _event_infos[eventId].name;
    }

    function tokenEvent(uint256 token)
        public
        view
        tokenExist(token)
        returns (uint256)
    {
        return _token_events[token];
    }

    function addTokenEvent(uint256 eventId, uint256 token)
        internal
        eventExist(eventId)
    {
        require(
            _token_events[token] == uint256(0),
            "Poap: token already existed"
        );
        _token_events[token] = eventId;
    }

    function removeTokenEvent(uint256 token) internal {
        _token_events[token] = uint256(0);
    }

    // For future extensions
    uint256[50] private ______gap;
}
