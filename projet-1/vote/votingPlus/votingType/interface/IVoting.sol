// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

interface IVoting {
    function setVoters(address _caller, address[] memory _voters) external;

    function openRegistration(address _caller) external;

    function setProposal(address _caller, string memory _description) external;

    function closeRegistration(address _caller) external;

    function openVotes(address _caller) external;

    function setVote(address _caller, uint256 _proposalId) external;

    function closeVotes(address _caller) external;

    function countVotes(address _caller) external;

    function getVoterVote(address _caller, address _voter)
        external
        view
        returns (uint256);

    function getWinner(address _caller)
        external
        view
        returns (
            bytes32 resWinningHash,
            uint256 resWinningId,
            string memory resDescription,
            uint256 resVoteCount
        );
}
