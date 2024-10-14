// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

// UTILS

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "hardhat/console.sol";

// VOTING CONTRACTS
import "../votingType/SpontaneousVoting.sol";
import "../roleManager/RoleManager.sol";
import "../memberManager/MemberManager.sol";

// ENUM
import "../_enum/EMemberTeams.sol";

contract TeamManager {
    // ///////////////////////////////////////////////////////////////////////////////////
    // STATE / CONSTRUCTOR / ...
    // ///////////////////////////////////////////////////////////////////////////////////

    RoleManager private roleManager_;
    MemberManager private memberManager_;

    // Teams  --------------------------------------------
    mapping(EMemberTeams => address[]) teams;

    // constructor --------------------------------------------
    constructor(address _roleManagerAddress, address _memberManagerAddress) {
        roleManager_ = RoleManager(_roleManagerAddress);
        memberManager_ = MemberManager(_memberManagerAddress);
    }

    // ///////////////////////////////////////////////////////////////////////////////////
    // FUNCTIONS
    // ///////////////////////////////////////////////////////////////////////////////////

    // /////////////////////////////////////////////////
    // MANAGE TEAMS MEMBERS
    // /////////////////////////////////////////////////

    function addMemberToTeam(
        address _caller,
        address _membersAddress,
        EMemberTeams _memberGroupId
    ) public {
        roleManager_.checkIsAdmin(_caller);

        // memberManager_.checkIsMemberExist(_membersAddress);

        teams[_memberGroupId].push(_membersAddress);
    }

    // /////////////////////////////////////////////////
    // GET TEAM
    // /////////////////////////////////////////////////

    function getTeam(address _caller, EMemberTeams _memberGroupId)
        public
        view
        returns (address[] memory)
    {
        roleManager_.checkIsAdmin(_caller);
        return teams[_memberGroupId];
    }
}
