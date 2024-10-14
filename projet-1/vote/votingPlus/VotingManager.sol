// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

// import "hardhat/console.sol";

// ENUMS
import "./_enum/EVotingTypes.sol";
import "./_enum/EVotingStatus.sol";

// ERROR
import "./_error/Errors.sol";

// MANAGER CONTRACTS
import "./roleManager/RoleManager.sol";
import "./memberManager/MemberManager.sol";
import "./teamManager/TeamManager.sol";

// INTERFACE VOTING CONTRACTS
import "./votingType/interface/IVoting.sol";

// VOTING CONTRACTS
import "./votingType/OfficialVoting.sol";

//import "./votingType/SpontaneousVoting.sol";

// ///////////////////////////////////////////////////////////////////////////////////

contract VotingManager is Errors {
    // ///////////////////////////////////////////////////////////////////////////////////
    // STATE / CONSTRUCTOR / ...
    // ///////////////////////////////////////////////////////////////////////////////////

    // Instance contracts --------------------------------------------
    RoleManager roleManager_;
    MemberManager memberManager_;
    TeamManager teamManager_;

    // Voting contracts --------------------------------------------
    mapping(EVotingTypes => address[]) votingCampaigns;

    // constructor --------------------------------------------
    constructor() {
        roleManager_ = new RoleManager(msg.sender);
        memberManager_ = new MemberManager(address(roleManager_));
        teamManager_ = new TeamManager(
            address(roleManager_),
            address(memberManager_)
        );
    }

    // ///////////////////////////////////////////////////////////////////////////////////
    // FUNCTIONS
    // ///////////////////////////////////////////////////////////////////////////////////

    // /////////////////////////////////////////////////
    // CREATE NEW VOTING CAMPAIGN
    // /////////////////////////////////////////////////

    function CreateNewVoting(
        EVotingTypes _votingType,
        EMemberTeams _memberTeams
    ) external {
        address newVotingCampaignAddress;

        // Create OFFICIAL Voting ---------------
        if (_votingType == EVotingTypes.OFFICIAL) {
            roleManager_.checkIsAdmin(msg.sender);
            newVotingCampaignAddress = address(
                new OfficialVoting(
                    msg.sender,
                    address(this),
                    address(roleManager_),
                    address(memberManager_),
                    address(teamManager_),
                    _memberTeams
                )
            );
        }
        // Create SPONTANEAOUS Voting ---------------
        else if (_votingType == EVotingTypes.SPONTANEAOUS) {
            roleManager_.checkIsVoter(msg.sender);
            // type de vote avec logique different ici
        }
        // Contract voting not exist ---------------
        else revert VotingContractNotExist(_votingType);

        votingCampaigns[_votingType].push(newVotingCampaignAddress);
    }

    // /////////////////////////////////////////////////
    // GET CONTRACT INSTANCE
    // /////////////////////////////////////////////////

    function getContractInstance(
        EVotingTypes _votingType,
        uint256 _indexContract
    ) internal view returns (IVoting) {
        address campaignAddress;

        // OFFICIAL
        if (_votingType == EVotingTypes.OFFICIAL) {
            campaignAddress = votingCampaigns[EVotingTypes.OFFICIAL][
                _indexContract
            ];
        }
        // SPONTANEAOUS
        else if (_votingType == EVotingTypes.SPONTANEAOUS) {
            campaignAddress = votingCampaigns[EVotingTypes.SPONTANEAOUS][
                _indexContract
            ];
        }
        // ERROR
        else revert("Error");

        IVoting campaignInstance_ = IVoting(campaignAddress);
        return campaignInstance_;
    }

    // /////////////////////////////////////////////////
    // Change voting status
    // /////////////////////////////////////////////////

    function changeVotingStatus(
        EVotingTypes _votingType,
        uint256 _indexContract,
        EVotingStatus _status
    ) external {
        IVoting campaignInstance_ = getContractInstance(
            _votingType,
            _indexContract
        );

        // OPEN_PROPOSAL
        if (_status == EVotingStatus.OPEN_PROPOSAL) {
            campaignInstance_.openRegistration(msg.sender);
        }
        // CLOSE_PROPOSAL
        else if (_status == EVotingStatus.CLOSE_PROPOSAL) {
            campaignInstance_.closeRegistration(msg.sender);
        }
        // OPEN_VOTING
        else if (_status == EVotingStatus.OPEN_VOTING) {
            campaignInstance_.openVotes(msg.sender);
        }
        // CLOSE_VOTING
        else if (_status == EVotingStatus.CLOSE_VOTING) {
            campaignInstance_.closeVotes(msg.sender);
            campaignInstance_.countVotes(msg.sender);
        }
        // DRAFT
        else if (_status == EVotingStatus.DRAFT) {
            //
        }
        // PAUSE
        else if (_status == EVotingStatus.PAUSE) {
            //
        }
        // CANCEL
        else if (_status == EVotingStatus.CANCEL) {
            //
        }
        // REVERT ERROR
        else revert InvalidActionContract(_status);
    }

    // /////////////////////////////////////////////////
    // set new Voters
    // /////////////////////////////////////////////////

    function setVoters(
        EVotingTypes _votingType,
        uint256 _indexContract,
        address[] memory _votersArray // ["0x5c6B0f7Bf3E7ce046039Bd8FABdfD3f9F5021678"]
    ) external {
        memberManager_.checkIsMemberExist(
            msg.sender,
            0x5c6B0f7Bf3E7ce046039Bd8FABdfD3f9F5021678
        );

        IVoting campaignInstance_ = getContractInstance(
            _votingType,
            _indexContract
        );

        campaignInstance_.setVoters(msg.sender, _votersArray);
    }

    // /////////////////////////////////////////////////
    // set Proposal
    // /////////////////////////////////////////////////

    function setProposal(EVotingTypes _votingType, uint256 _indexContract)
        external
    {
        IVoting campaignInstance_ = getContractInstance(
            _votingType,
            _indexContract
        );

        campaignInstance_.setProposal(msg.sender, "Proposition de vote 1");
        campaignInstance_.setProposal(msg.sender, "Proposition de vote 2");
        campaignInstance_.setProposal(msg.sender, "Proposition de vote 3");
    }

    // /////////////////////////////////////////////////
    // set Vote
    // /////////////////////////////////////////////////

    function setVote(
        EVotingTypes _votingType,
        uint256 _indexContract,
        uint256 _indexVote
    ) external {
        IVoting campaignInstance_ = getContractInstance(
            _votingType,
            _indexContract
        );

        campaignInstance_.setVote(msg.sender, _indexVote);
    }

    // /////////////////////////////////////////////////
    // get Winner
    // /////////////////////////////////////////////////

    function getWinner(EVotingTypes _votingType, uint256 _indexContract)
        external
        view
        returns (
            bytes32 resWinningHash,
            uint256 resWinningId,
            string memory resDescription,
            uint256 resVoteCount
        )
    {
        IVoting campaignInstance_ = getContractInstance(
            _votingType,
            _indexContract
        );

        return campaignInstance_.getWinner(msg.sender);
    }

    // ///////////////////////////////////////////////////////////////////////////////////
    // ℹ️ℹ️ℹ️ AJOUT DE DONNER POUR TESTER ℹ️ℹ️ℹ️
    // ///////////////////////////////////////////////////////////////////////////////////

    function addDataTest() public {
        // SUPER ADMIN -----
        memberManager_.addMember(
            msg.sender,
            0x5B38Da6a701c568545dCfcB03FcB875f56beddC4, // Compte remix 1
            "Chuck SuperAdmin & admin",
            EMemberRoles.ADMIN_ROLE
        );

        roleManager_.assignRole(
            msg.sender,
            0x5B38Da6a701c568545dCfcB03FcB875f56beddC4, // Compte remix 1
            EMemberRoles.VOTER_ROLE
        );

        // ADMIN_ROLE -----
        memberManager_.addMember(
            msg.sender,
            0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2, // Compte remix 2
            "Leon Admin",
            EMemberRoles.ADMIN_ROLE
        );

        roleManager_.assignRole(
            msg.sender,
            0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2, // Compte remix 2
            EMemberRoles.VOTER_ROLE
        );

        memberManager_.addMember(
            msg.sender,
            0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db, // Compte remix 3
            "Manon Admin",
            EMemberRoles.ADMIN_ROLE
        );

        roleManager_.assignRole(
            msg.sender,
            0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db, // Compte remix 3
            EMemberRoles.VOTER_ROLE
        );

        // VOTER_ROLE -----
        memberManager_.addMember(
            msg.sender,
            0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB, // Compte remix 4
            "Tristan Voter",
            EMemberRoles.VOTER_ROLE
        );

        memberManager_.addMember(
            msg.sender,
            0x617F2E2fD72FD9D5503197092aC168c91465E7f2, // Compte remix 5
            "Sophia Voter",
            EMemberRoles.VOTER_ROLE
        );

        // VISITOR_ROLE -----
        memberManager_.addMember(
            msg.sender,
            0x17F6AD8Ef982297579C203069C1DbfFE4348c372, // Compte remix 6
            "Patrick Visitor",
            EMemberRoles.VISITOR_ROLE
        );

        // ADD MEMBER TO TEAM MARKETING -----
        teamManager_.addMemberToTeam(
            msg.sender,
            0x5B38Da6a701c568545dCfcB03FcB875f56beddC4, // Compte remix 1
            EMemberTeams.MARKETING
        );

        teamManager_.addMemberToTeam(
            msg.sender,
            0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2, // Compte remix 2
            EMemberTeams.MARKETING
        );

        teamManager_.addMemberToTeam(
            msg.sender,
            0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB, // Compte remix 4
            EMemberTeams.MARKETING
        );

        teamManager_.addMemberToTeam(
            msg.sender,
            0x617F2E2fD72FD9D5503197092aC168c91465E7f2, // Compte remix 5
            EMemberTeams.MARKETING
        );

        // ADD MEMBER TO TEAM DEVELOPPER -----
        teamManager_.addMemberToTeam(
            msg.sender,
            0x5B38Da6a701c568545dCfcB03FcB875f56beddC4, // Compte remix 1
            EMemberTeams.DEVELOPPER
        );

        teamManager_.addMemberToTeam(
            msg.sender,
            0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB, // Compte remix 4
            EMemberTeams.DEVELOPPER
        );
    }
}
