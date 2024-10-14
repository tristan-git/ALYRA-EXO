// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "hardhat/console.sol";

import "../VotingManager.sol";
import "../roleManager/RoleManager.sol";
import "../memberManager/MemberManager.sol";

contract SpontaneousVoting {
    uint256 toto = 225155;
    VotingManager private votingManager_;
    RoleManager private roleManager_;
    MemberManager private memberManager_;

    // constructor --------------------------------------------
    // constructor --------------------------------------------
    constructor(
        address _votingManagerAddress,
        address _roleManager,
        address _memberManager
    ) {
        votingManager_ = VotingManager(_votingManagerAddress);
        roleManager_ = RoleManager(_roleManager);
        memberManager_ = MemberManager(_memberManager);
    }

    function getToto(address _caller) public view returns (uint256) {
        require(
            roleManager_.hasRole(roleManager_.VISITOR_ROLE(), _caller),
            "Access denied: Requires VISITOR_ROLE role"
        );

        return toto;
    }
}
