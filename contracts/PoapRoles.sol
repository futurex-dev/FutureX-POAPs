// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./Roles.sol";

contract PoapRoles is Initializable {
    using Roles for Roles.Role;

    event AdminAdded(address indexed account);
    event AdminRemoved(address indexed account);
    event EventMinterAdded(uint256 indexed eventId, address indexed account);
    event EventMinterRemoved(uint256 indexed eventId, address indexed account);

    Roles.Role private _admins;
    mapping(uint256 => Roles.Role) private _minters;

    function initialize(address sender) public initializer {
        if (!isAdmin(sender)) {
            _addAdmin(sender);
        }
    }

    modifier onlyAdmin() {
        require(isAdmin(msg.sender));
        _;
    }

    modifier onlyEventMinter(uint256 eventId) {
        require(isEventMinter(eventId, msg.sender));
        _;
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

    function addEventMinter(uint256 eventId, address account)
        public
        onlyEventMinter(eventId)
    {
        _addEventMinter(eventId, account);
    }

    function addAdmin(address account) public onlyAdmin {
        _addAdmin(account);
    }

    function renounceEventMinter(uint256 eventId) public {
        _removeEventMinter(eventId, msg.sender);
    }

    function renounceAdmin() public {
        _removeAdmin(msg.sender);
    }

    function removeEventMinter(uint256 eventId, address account)
        public
        onlyAdmin
    {
        _removeEventMinter(eventId, account);
    }

    function removeAdmin(address account) public onlyAdmin {
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

    function _removeAdmin(address account) internal {
        _admins.remove(account);
        emit AdminRemoved(account);
    }

    // For future extensions
    uint256[50] private ______gap;
}
