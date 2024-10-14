// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "../_enum/EVotingTypes.sol";
import "../_enum/EVotingStatus.sol";

contract Errors {
    error VotingContractNotExist(EVotingTypes votingType);
    error InvalidActionContract(EVotingStatus votingStatus);
}
