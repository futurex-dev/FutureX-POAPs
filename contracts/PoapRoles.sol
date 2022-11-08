// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./Roles.sol";

contract PoapRoles is Initializable {
    using Roles for Roles.Role;

    event AdminAdded(address indexed account);
    event AdminRemoved(address indexed account);
    event EventCreatorAdded(uint256 indexed eventId, address indexed account);
    event EventCreatorRemoved(uint256 indexed eventId);
    event EventMinterAdded(uint256 indexed eventId, address indexed account);
    event EventMinterRemoved(uint256 indexed eventId, address indexed account);

    Roles.Role private _admins;
    mapping(uint256 => Roles.Role) private _minters;
    mapping(uint256 => address) private _creators;

    function __ROLE_init(address sender) public initializer {
        if (!isAdmin(sender)) {
            _addAdmin(sender);
        }
    }

    function _requireAdmin() internal view {
        require(isAdmin(msg.sender), "Poap: only admin can do it");
    }

    function _requireEventMinter(uint256 eventId) internal view {
        require(
            isEventMinter(eventId, msg.sender),
            "Poap: only event-minter or admin can do it"
        );
    }

    function _requireEventCreator(uint256 eventId) internal view {
        require(
            isEventCreator(eventId, msg.sender),
            "Poap: only event-creator or admin can do it"
        );
    }

    function isAdmin(address account) public view returns (bool) {
        return _admins.has(account);
    }

    function isEventCreator(uint256 eventId, address account)
        public
        view
        returns (bool)
    {
        return isAdmin(account) || _creators[eventId] == account;
    }

    function isEventMinter(uint256 eventId, address account)
        public
        view
        returns (bool)
    {
        return
            isEventCreator(eventId, account) || _minters[eventId].has(account);
    }

    function _addEventCreator(uint256 eventId, address account) internal {
        require(_creators[eventId] == address(0), "Poap: already have creator");

        _creators[eventId] = account;

        emit EventCreatorAdded(eventId, account);
    }

    function addEventMinter(uint256 eventId, address account) public {
        _requireEventCreator(eventId);

        _beforeAddEventMinter(eventId, account);
        _addEventMinter(eventId, account);
    }

    function addAdmin(address account) public {
        _requireAdmin();
        _addAdmin(account);
    }

    function renounceEventMinter(uint256 eventId) public {
        _removeEventMinter(eventId, msg.sender);
    }

    function renounceAdmin() public {
        _removeAdmin(msg.sender);
    }

    function renounceEventCreator(uint256 eventId) public {
        _requireEventCreator(eventId);

        _removeEventCreator(eventId);
    }

    function removeEventMinter(uint256 eventId, address account) public {
        _requireEventCreator(eventId);

        _removeEventMinter(eventId, account);
    }

    function removeAdmin(address account) public {
        _requireAdmin();
        _removeAdmin(account);
    }

    function _addEventMinter(uint256 eventId, address account) internal {
        _minters[eventId].add(account);
        emit EventMinterAdded(eventId, account);
    }

    function _addAdmin(address account) internal {
        _admins.add(account);
        emit AdminAdded(account);
    }

    function _removeEventMinter(uint256 eventId, address account) internal {
        _minters[eventId].remove(account);
        emit EventMinterRemoved(eventId, account);
    }

    function _removeEventCreator(uint256 eventId) internal {
        delete _creators[eventId];
        emit EventCreatorRemoved(eventId);
    }

    function _removeAdmin(address account) internal {
        _admins.remove(account);
        emit AdminRemoved(account);
    }

    function _beforeAddEventMinter(uint256 eventId, address account)
        internal
        virtual
    {}

    // For future extensions
    uint256[50] private ______gap;
}
