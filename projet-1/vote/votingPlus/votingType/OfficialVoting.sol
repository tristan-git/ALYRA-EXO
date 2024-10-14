// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "@openzeppelin/contracts/utils/Strings.sol";
// import "hardhat/console.sol";

// ENUMS
import "../_enum/EMemberTeams.sol";
import "../_enum/EWorkflowStatus.sol";

// EVENTS
import "../_event/Events.sol";

// MANAGER CONTRACTS
import "../VotingManager.sol";
import "../roleManager/RoleManager.sol";
import "../memberManager/MemberManager.sol";
import "../teamManager/TeamManager.sol";

// INTERFACE CONTRACTS
import "../votingType/interface/IVoting.sol";

contract OfficialVoting is IVoting, Events {
    VotingManager private votingManager_;
    RoleManager private roleManager_;
    MemberManager private memberManager_;
    TeamManager private teamManager_;

    uint256[] winningProposalIds;
    bytes32 winningHash;
    bool thisVotingIsFinish;

    EWorkflowStatus currentStatus = EWorkflowStatus.RegisteringVoters;

    // Voter --------------------------------------------
    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint256 votedProposalId;
    }

    address[] voterAddresses;
    mapping(address => Voter) voters;

    // Proposal --------------------------------------------
    struct Proposal {
        string description;
        uint256 voteCount;
    }

    Proposal[] proposals;

    // constructor --------------------------------------------
    constructor(
        address _caller,
        address _votingManagerAddress,
        address _roleManager,
        address _memberManager,
        address _teamManager,
        EMemberTeams _memberTeams
    ) {
        votingManager_ = VotingManager(_votingManagerAddress);
        roleManager_ = RoleManager(_roleManager);
        memberManager_ = MemberManager(_memberManager);
        teamManager_ = TeamManager(_teamManager);

        address[] memory teamVoters = teamManager_.getTeam(
            _caller,
            _memberTeams
        );

        setVoters(_caller, teamVoters);
    }

    // modifiers --------------------------------------------
    modifier isNotFinish() {
        require(!thisVotingIsFinish, "Winner proposal are already annouced");
        _;
    }

    // ///////////////////////////////////////////////////////////////////////////////////
    // FUNCTIONS
    // ///////////////////////////////////////////////////////////////////////////////////

    // /////////////////////////////////////////////////
    // set Voters
    // /////////////////////////////////////////////////

    function setVoters(address _caller, address[] memory _voters)
        public
        isNotFinish
    {
        roleManager_.checkIsAdmin(_caller);
        require(_voters.length > 0, "The voters list is empty");

        for (uint256 i = 0; i < _voters.length; ++i) {
            if (voters[_voters[i]].isRegistered) continue;
            else {
                voters[_voters[i]] = Voter({
                    isRegistered: true,
                    hasVoted: false,
                    votedProposalId: 0
                });

                voterAddresses.push(_voters[i]);
                emit VoterRegistered(_voters[i]);
            }
        }
    }

    // /////////////////////////////////////////////////
    // 2 - L'administrateur du vote commence la session d'enregistrement de la proposition.
    // /////////////////////////////////////////////////
    function openRegistration(address _caller) public isNotFinish {
        roleManager_.checkIsAdmin(_caller);

        require(
            currentStatus == EWorkflowStatus.RegisteringVoters,
            "Voters must be added first"
        );

        emit WorkflowStatusChange(
            currentStatus,
            EWorkflowStatus.ProposalsRegistrationStarted
        );

        currentStatus = EWorkflowStatus.ProposalsRegistrationStarted;
    }

    // /////////////////////////////////////////////////
    // 3 - Les électeurs inscrits sont autorisés à enregistrer leurs propositions pendant que la session d'enregistrement est active.
    // /////////////////////////////////////////////////
    function setProposal(address _caller, string memory _description)
        external
        isNotFinish
    {
        roleManager_.checkIsVoter(_caller);

        require(
            currentStatus == EWorkflowStatus.ProposalsRegistrationStarted,
            "Proposal registration not started or already finished"
        );

        require(!Strings.equal(_description, ""), "Proposal cannot be empty");

        proposals.push(Proposal(_description, 0));
        emit ProposalRegistered(proposals.length);
    }

    // /////////////////////////////////////////////////
    // 4 - L'administrateur de vote met fin à la session d'enregistrement des propositions.
    // /////////////////////////////////////////////////

    function closeRegistration(address _caller) external isNotFinish {
        roleManager_.checkIsAdmin(_caller);
        /*
        require(
            currentStatus == WorkflowStatus.ProposalsRegistrationStarted,
            "Registration session not started or already close"
        );
        */

        require(proposals.length > 0, "No proposals available");

        emit WorkflowStatusChange(
            currentStatus,
            EWorkflowStatus.ProposalsRegistrationEnded
        );

        currentStatus = EWorkflowStatus.ProposalsRegistrationEnded;
    }

    // /////////////////////////////////////////////////
    // 5 - L'administrateur du vote commence la session de vote.
    // /////////////////////////////////////////////////

    function openVotes(address _caller) external isNotFinish {
        roleManager_.checkIsAdmin(_caller);

        /*
        require(
            currentStatus == WorkflowStatus.ProposalsRegistrationEnded,
            "Proposal registration session not ended"
        );
        */

        emit WorkflowStatusChange(
            currentStatus,
            EWorkflowStatus.VotingSessionStarted
        );

        currentStatus = EWorkflowStatus.VotingSessionStarted;
    }

    // /////////////////////////////////////////////////
    // 6 - Les électeurs inscrits votent pour leur proposition préférée.
    // /////////////////////////////////////////////////

    function setVote(address _caller, uint256 _proposalId)
        external
        isNotFinish
    {
        roleManager_.checkIsVoter(_caller);
        require(!voters[_caller].hasVoted, "You have already voted");
        require(voters[_caller].isRegistered, "Not register for this vote");

        require(
            currentStatus == EWorkflowStatus.VotingSessionStarted,
            "Voting session not started"
        );

        ++proposals[_proposalId].voteCount;
        voters[_caller].hasVoted = true;
        voters[_caller].votedProposalId = _proposalId;
        emit Voted(_caller, _proposalId);
    }

    // /////////////////////////////////////////////////
    //  L 'administrateur du vote met fin à la session de vote
    // /////////////////////////////////////////////////

    function closeVotes(address _caller) external isNotFinish {
        roleManager_.checkIsAdmin(_caller);

        require(
            currentStatus == EWorkflowStatus.VotingSessionStarted,
            "Voting session not started"
        );

        emit WorkflowStatusChange(
            currentStatus,
            EWorkflowStatus.VotingSessionEnded
        );

        currentStatus = EWorkflowStatus.VotingSessionEnded;
    }

    // /////////////////////////////////////////////////
    // 7 - L'administrateur du vote comptabilise les votes.
    // /////////////////////////////////////////////////
    function countVotes(address _caller) external isNotFinish {
        roleManager_.checkIsAdmin(_caller);

        require(
            currentStatus == EWorkflowStatus.VotingSessionEnded,
            "Voting session not ended"
        );

        uint256 bestVoteCount = 0;
        uint256 nbWinner = 0;
        for (uint256 i = 0; i < proposals.length; ++i) {
            if (proposals[i].voteCount >= bestVoteCount) {
                bestVoteCount = proposals[i].voteCount;
                ++nbWinner;
            }
        }

        uint256[] memory tempWinningProposalIds = new uint256[](nbWinner);

        bestVoteCount = 0;
        nbWinner = 0;
        for (uint256 i = 0; i < proposals.length; ++i) {
            if (proposals[i].voteCount >= bestVoteCount) {
                tempWinningProposalIds[nbWinner] = i;
                bestVoteCount = proposals[i].voteCount;
                ++nbWinner;
            }
        }

        // Several winners -------------
        // on recommence une session de votes avec les proposition ex eco
        if (nbWinner > 1) {
            // Set only winner proposal
            Proposal[] memory tempProposals = new Proposal[](nbWinner);
            for (uint256 i = 0; i < tempWinningProposalIds.length; ++i) {
                tempProposals[i] = proposals[tempWinningProposalIds[i]];
            }
            delete proposals;

            for (uint256 i = 0; i < tempWinningProposalIds.length; ++i) {
                proposals.push(
                    Proposal(
                        tempProposals[tempWinningProposalIds[i]].description,
                        0
                    )
                );
            }

            // reset voter choice
            for (uint256 i = 0; i < voterAddresses.length; ++i) {
                voters[voterAddresses[i]] = Voter({
                    isRegistered: true,
                    hasVoted: false,
                    votedProposalId: 0
                });
            }

            emit WorkflowStatusChange(
                currentStatus,
                EWorkflowStatus.VotingSessionStarted
            );

            currentStatus = EWorkflowStatus.VotingSessionStarted;
        }
        // 1 winner -------------
        else {
            winningHash = keccak256(
                abi.encodePacked(
                    tempWinningProposalIds[0],
                    proposals[tempWinningProposalIds[0]].description,
                    proposals[tempWinningProposalIds[0]].voteCount
                )
            );

            emit WorkflowStatusChange(
                currentStatus,
                EWorkflowStatus.VotesTallied
            );

            winningProposalIds = tempWinningProposalIds;
            currentStatus = EWorkflowStatus.VotesTallied;
            thisVotingIsFinish = true;
        }
    }

    // /////////////////////////////////////////////////
    // 8 - getVoterVote
    // /////////////////////////////////////////////////
    function getVoterVote(address _caller, address _voter)
        external
        view
        returns (uint256)
    {
        roleManager_.checkIsVoter(_caller);
        require(voters[_voter].hasVoted, "This voter has not voted yet");

        return voters[_voter].votedProposalId;
    }

    // /////////////////////////////////////////////////
    // 9 - getWinner
    // /////////////////////////////////////////////////
    function getWinner(address _caller)
        external
        view
        returns (
            bytes32 resWinningHash,
            uint256 resWinningId,
            string memory resDescription,
            uint256 resVoteCount
        )
    {
        require(thisVotingIsFinish, "Winner proposal are not already annouced");
        roleManager_.checkIsVoter(_caller);

        return (
            winningHash,
            winningProposalIds[0],
            proposals[winningProposalIds[0]].description,
            proposals[winningProposalIds[0]].voteCount
        );
    }
}
