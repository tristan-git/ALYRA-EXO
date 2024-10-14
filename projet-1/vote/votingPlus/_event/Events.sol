// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "../_enum/EWorkflowStatus.sol";
import "../_enum/EVotingStatus.sol";

contract Events {
    event VoterRegistered(address voterAddress);

    event WorkflowStatusChange(
        EWorkflowStatus previousStatus,
        EWorkflowStatus newStatus
    );

    event ProposalRegistered(uint256 proposalId);

    event Voted(address voter, uint256 proposalId);
}
