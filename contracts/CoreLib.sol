// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

library CoreLib {
    bytes32 constant public CORE = keccak256("CORE");
    bytes32 constant public COORD = keccak256("COORDINATOR");
    bytes32 constant public EXE = keccak256("EXECUTABLES");
    bytes32 constant public PROPS = keccak256("PROPOSALS");
    bytes32 constant public VOTE_BOOTH = keccak256("VOTING_BOOTH");
    bytes32 constant public VOTE_WEIGHT = keccak256("VOTE_WEIGHT");
}