// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./PoapEvent.sol";
import "./Roles.sol";

contract PoapRoles is Initializable, PoapEvent {
    using Roles for Roles.Role;

    event AdminAdded(address indexed account);
    event AdminRemoved(address indexed account);
    event EventMinterAdded(uint256 indexed eventId, address indexed account);
    event EventMinterRemoved(uint256 indexed eventId, address indexed account);

    Roles.Role private _admins;
    mapping(uint256 => Roles.Role) private _minters;

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

    function isAdmin(address account) public view returns (bool) {
        return _admins.has(account);
    }

    function isEventMinter(uint256 eventId, address account)
        public
        view
        returns (bool)
    {
        return isAdmin(account) || _minters[eventId].has(account);
    }

    function addEventMinter(uint256 eventId, address account) public {
        _requireEventMinter(eventId);
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

    function removeEventMinter(uint256 eventId, address account) public {
        _requireAdmin();
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
        _requireEventExist(eventId);
        _minters[eventId].remove(account);
        emit EventMinterRemoved(eventId, account);
    }

    function _removeAdmin(address account) internal {
        _admins.remove(account);
        emit AdminRemoved(account);
    }

    // For future extensions
    uint256[50] private ______gap;
}
