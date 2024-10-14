// SPDX-License-Identifier: MIT
pragma solidity 0.8.28; 

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "hardhat/console.sol";

contract Voting is Ownable {
    // ////////////////////////////////////////////////////////////////////////////////////////////////////
    uint256 winningProposalId;

    enum WorkflowStatus {
        RegisteringVoters, // 0
        ProposalsRegistrationStarted, // 1
        ProposalsRegistrationEnded, // 2
        VotingSessionStarted, // 3
        VotingSessionEnded, // 4
        VotesTallied // 5
    }

    WorkflowStatus currentStatus = WorkflowStatus.RegisteringVoters;

    // struct --------------------------------------------
    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint256 votedProposalId;
    }

    struct Proposal {
        string description;
        uint256 voteCount;
    }

    // mapping --------------------------------------------

    mapping(address => Voter) voters;
    Proposal[] proposals;

    // event --------------------------------------------
    event VoterRegistered(address voterAddress);

    event WorkflowStatusChange(
        WorkflowStatus previousStatus,
        WorkflowStatus newStatus
    );

    event ProposalRegistered(uint256 proposalId);

    event Voted(address voter, uint256 proposalId);

    // modifier --------------------------------------------
    modifier onlySubcribeVoter() {
        require(voters[msg.sender].isRegistered, "Not autorised");
        _;
    }

    // constructor --------------------------------------------
    constructor() Ownable(msg.sender) {}

    // ////////////////////////////////////////////////////////////////////////////////////////////////////

    // 1 - L'administrateur du vote enregistre une liste blanche d'électeurs identifiés par leur adresse Ethereum.
    function setVoters(address[] memory _voters) external onlyOwner {
        require(_voters.length > 0, "The voters list is empty");

        for (uint256 i = 0; i <= _voters.length - 1; i++) {
            if (voters[_voters[i]].isRegistered) {
                continue;
            } else {
                voters[_voters[i]] = Voter({
                    isRegistered: true,
                    hasVoted: false,
                    votedProposalId: 0
                });

                emit VoterRegistered(_voters[i]);
            }
        }
    }

    // 2 - L'administrateur du vote commence la session d'enregistrement de la proposition.
    function openRegistration() external onlyOwner {
        require(
            currentStatus == WorkflowStatus.RegisteringVoters,
            "Voters must be added first"
        );

        emit WorkflowStatusChange(
            currentStatus,
            WorkflowStatus.ProposalsRegistrationStarted
        );

        currentStatus = WorkflowStatus.ProposalsRegistrationStarted;
    }

    // 3 - Les électeurs inscrits sont autorisés à enregistrer leurs propositions pendant que la session d'enregistrement est active.
    function setProposal(string memory _description)
        external
        onlySubcribeVoter
    {
        require(
            currentStatus == WorkflowStatus.ProposalsRegistrationStarted,
            "Proposal registration not started or already finished"
        );
        require(!Strings.equal(_description, ""), "Proposal cannot be empty");

        proposals.push(Proposal(_description, 0));
        emit ProposalRegistered(proposals.length);
    }

    // 4 - L'administrateur de vote met fin à la session d'enregistrement des propositions.
    function closeRegistration() external onlyOwner {
        require(
            currentStatus == WorkflowStatus.ProposalsRegistrationStarted,
            "Registration session not started or already close"
        );

        require(proposals.length > 0, "No proposals available");

        emit WorkflowStatusChange(
            currentStatus,
            WorkflowStatus.ProposalsRegistrationEnded
        );

        currentStatus = WorkflowStatus.ProposalsRegistrationEnded;
    }

    // 5 - L'administrateur du vote commence la session de vote.
    function openVotes() external onlyOwner {
        require(
            currentStatus == WorkflowStatus.ProposalsRegistrationEnded,
            "Proposal registration session not ended"
        );

        emit WorkflowStatusChange(
            currentStatus,
            WorkflowStatus.VotingSessionStarted
        );

        currentStatus = WorkflowStatus.VotingSessionStarted;
    }

    // 6 - Les électeurs inscrits votent pour leur proposition préférée.
    function setVote(uint256 _proposalId) external onlySubcribeVoter {
        require(!voters[msg.sender].hasVoted, "You have already voted");

        require(
            currentStatus == WorkflowStatus.VotingSessionStarted,
            "Voting session not started"
        );

        ++proposals[_proposalId].voteCount;
        voters[msg.sender].hasVoted = true;
        voters[msg.sender].votedProposalId = _proposalId;

        emit Voted(msg.sender, _proposalId);
    }

    // L 'administrateur du vote met fin à la session de vote
    function closeVotes() external onlyOwner {
        require(
            currentStatus == WorkflowStatus.VotingSessionStarted,
            "Voting session not started"
        );

        emit WorkflowStatusChange(
            currentStatus,
            WorkflowStatus.VotingSessionEnded
        );

        currentStatus = WorkflowStatus.VotingSessionEnded;
    }

    // 7 - L'administrateur du vote comptabilise les votes. // VotesTallied
    function countVotes() external onlyOwner {
        require(
            currentStatus == WorkflowStatus.VotingSessionEnded,
            "Voting session not ended"
        );

        uint256 tempWinningProposalId;
        uint256 bestVoteCount = 0;

        for (uint256 i = 0; i <= proposals.length - 1; i++) {
            if (proposals[i].voteCount > bestVoteCount) {
                tempWinningProposalId = i;
            }
        }

        winningProposalId = tempWinningProposalId;

        emit WorkflowStatusChange(currentStatus, WorkflowStatus.VotesTallied);
        currentStatus = WorkflowStatus.VotesTallied;
    }

    // 8 - getVoterVote --------------------------------------------
    function getVoterVote(address _voter)
        external
        view
        onlySubcribeVoter
        returns (uint256)
    {
        require(voters[_voter].hasVoted, "This voter has not voted yet");
        return voters[_voter].votedProposalId;
    }

    // 9 - getWinner --------------------------------------------
    function getWinner()
        external
        view
        onlySubcribeVoter
        returns (Proposal memory)
    {
        require(
            currentStatus == WorkflowStatus.VotesTallied,
            "Votes have not been tallied yet"
        );

        return proposals[winningProposalId];
    }
}
