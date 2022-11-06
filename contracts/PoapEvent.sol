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
        string meta_uri;
        bool status;
        address[] users;
        mapping(address => uint256) reverse_index;
    }

    event EventAdded(
        uint256 indexed eventId,
        address indexed creator,
        string eventURI
    );

    mapping(uint256 => Event) private _event_infos;
    mapping(uint256 => uint256) private _token_events;
    mapping(uint256 => bool) private _event_exist;

    function _requireEventExist(uint256 eventId) internal view {
        require(_event_exist[eventId], "Poap: event not exists");
    }

    function __EVENT_init() public initializer {}

    function _createEvent(uint256 eventId, string memory eventURI) internal {
        require(!_event_exist[eventId], "Poap: event already existed");
        _event_exist[eventId] = true;
        _event_infos[eventId].meta_uri = eventURI;
        emit EventAdded(eventId, msg.sender, eventURI);
    }

    function _addEventUser(uint256 eventId, address user) internal {
        _requireEventExist(eventId);
        require(
            _event_infos[eventId].reverse_index[user] == uint256(0),
            "Poap: already assigned the event"
        );
        // user indexs start from 1
        _event_infos[eventId].reverse_index[user] =
            _event_infos[eventId].users.length +
            1;
        _event_infos[eventId].users.push(user);
    }

    function _removeEventUser(uint256 eventId, address user) internal {
        _requireEventExist(eventId);
        require(
            _event_infos[eventId].reverse_index[user] != uint256(0),
            "Poap: user didn't exist"
        );
        uint256 user_index = _event_infos[eventId].reverse_index[user] - 1;
        uint256 total_users = _event_infos[eventId].users.length - 1;
        _event_infos[eventId].users[user_index] = _event_infos[eventId].users[
            total_users
        ];
        delete _event_infos[eventId].reverse_index[user];
        _event_infos[eventId].users.pop();
    }

    function eventHasUser(uint256 eventId, address user)
        public
        view
        returns (bool)
    {
        _requireEventExist(eventId);
        return _event_infos[eventId].reverse_index[user] != uint256(0);
    }

    function balanceOfEvent(uint256 eventId) public view returns (uint256) {
        _requireEventExist(eventId);
        return _event_infos[eventId].users.length;
    }

    function userOfEventByIndex(uint256 eventId, uint256 index)
        public
        view
        returns (address)
    {
        _requireEventExist(eventId);
        return _event_infos[eventId].users[index];
    }

    function eventMetaURI(uint256 eventId) public view returns (string memory) {
        _requireEventExist(eventId);
        return _event_infos[eventId].meta_uri;
    }

    function tokenEvent(uint256 token) public view returns (uint256) {
        require(_token_events[token] != uint256(0), "Poap: token wasn't exist");
        return _token_events[token];
    }

    function _addTokenEvent(uint256 eventId, uint256 token) internal {
        _requireEventExist(eventId);
        require(
            _token_events[token] == uint256(0),
            "Poap: token already existed"
        );
        _token_events[token] = eventId;
    }

    function _removeTokenEvent(uint256 token) internal {
        _token_events[token] = uint256(0);
    }

    function _authorize(uint256 eventId) internal {
        _requireEventExist(eventId);
        _event_infos[eventId].status = true;
    }

    function _unauthorize(uint256 eventId) internal {
        _requireEventExist(eventId);
        _event_infos[eventId].status = false;
    }

    function authorized(uint256 eventId) public view returns (bool) {
        _requireEventExist(eventId);
        return _event_infos[eventId].status;
    }

    // For future extensions
    uint256[50] private ______gap;
}
