// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

enum EVotingStatus {
    OPEN_PROPOSAL, // 0
    CLOSE_PROPOSAL, // 1
    OPEN_VOTING, // 2
    CLOSE_VOTING, // 3
    DRAFT, // 4
    PAUSE, // 5
    CANCEL // 6
}
