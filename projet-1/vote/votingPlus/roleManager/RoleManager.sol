// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

// UTILS
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "hardhat/console.sol";

// ENUM
import "../_enum/EMemberRoles.sol";

contract RoleManager is AccessControl {
    // ///////////////////////////////////////////////////////////////////////////////////
    // STATE / CONSTRUCTOR / ...
    // ///////////////////////////////////////////////////////////////////////////////////

    // Roles --------------------------------------------
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant VOTER_ROLE = keccak256("VOTER_ROLE");
    bytes32 public constant VISITOR_ROLE = keccak256("VISITOR_ROLE");
    bytes32[4] roles = [
        DEFAULT_ADMIN_ROLE,
        ADMIN_ROLE,
        VOTER_ROLE,
        VISITOR_ROLE
    ];

    // constructor --------------------------------------------
    constructor(address _initialOwner) {
        _grantRole(DEFAULT_ADMIN_ROLE, _initialOwner);
        _grantRole(ADMIN_ROLE, _initialOwner);
    }

    // ///////////////////////////////////////////////////////////////////////////////////
    // FUNCTIONS
    // ///////////////////////////////////////////////////////////////////////////////////

    // /////////////////////////////////////////////////
    // MANAGE ROLES
    // /////////////////////////////////////////////////

    // Revoke user role ---------------
    function revokeMemberRole(
        address _caller,
        address _account,
        EMemberRoles _role
    ) external {
        checkIsSuperAdmin(_caller);
        bool success = _revokeRole(roles[uint256(_role)], _account);
        require(success, unicode"❌ ERROR ROLE REVOCATION");
    }

    // assign user Role ---------------
    function assignRole(
        address _caller,
        address _memberAddress,
        EMemberRoles _roleId
    ) external {
        checkIsAdmin(_caller);
        _grantRole(roles[uint256(_roleId)], _memberAddress);
    }

    // /////////////////////////////////////////////////
    // CHECK ROLES
    // /////////////////////////////////////////////////

    function checkIsSuperAdmin(address _caller) public view {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _caller),
            unicode"🚫 UNOTORISED ACCESS"
        );
    }

    function checkIsAdmin(address _caller) public view {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _caller) ||
                hasRole(ADMIN_ROLE, _caller),
            unicode"🚫 UNOTORISED ACCESS"
        );
    }

    function checkIsVoter(address _caller) public view {
        require(hasRole(VOTER_ROLE, _caller), unicode"🚫 UNOTORISED ACCESS");
    }
}
