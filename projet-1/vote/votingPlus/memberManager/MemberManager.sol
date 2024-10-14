// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

// UTILS
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "hardhat/console.sol";

// CONTRACTS
import "../roleManager/RoleManager.sol";

// ENUM
import "../_enum/EMemberRoles.sol";

contract MemberManager {
    // ///////////////////////////////////////////////////////////////////////////////////
    // STATE / CONSTRUCTOR / ...
    // ///////////////////////////////////////////////////////////////////////////////////

    RoleManager private roleManager_;

    // Members --------------------------------------------
    struct Member {
        string name;
        bool isCreated;
        bool isDisabled;
    }

    mapping(address => Member) members;

    // constructor --------------------------------------------
    constructor(address _roleManagerAddress) {
        roleManager_ = RoleManager(_roleManagerAddress);
    }

    // ///////////////////////////////////////////////////////////////////////////////////
    // FUNCTIONS
    // ///////////////////////////////////////////////////////////////////////////////////

    // /////////////////////////////////////////////////
    // MANAGE MEMBERS
    // /////////////////////////////////////////////////

    function addMember(
        address _caller,
        address _membersAddress,
        string memory _name,
        EMemberRoles _roleId
    ) public {
        roleManager_.checkIsAdmin(_caller);

        require(
            !members[_membersAddress].isCreated,
            unicode"❌ Member already exist"
        );

        // add member
        members[_membersAddress] = Member({
            name: _name,
            isCreated: true,
            isDisabled: false
        });

        // add role
        // TODO ------> verifier quon ne modifie pas le role du super admin !!
        roleManager_.assignRole(_caller, _membersAddress, _roleId);
    }

    // /////////////////////////////////////////////////
    // CHECK ROLES
    // /////////////////////////////////////////////////

    function checkIsMemberExist(address _caller, address _membersAddress)
        public
        view
    {
        roleManager_.checkIsAdmin(_caller);
        require(
            !members[_membersAddress].isCreated,
            unicode"❌ Member already exist"
        );
    }
}
