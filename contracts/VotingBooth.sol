// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./BaseSystem.sol";

// Use ERC20Votes for delegation of votes
// GovernerVotes for where to hook into token 

contract VotingBooth is BaseSystem {

    constructor(address _core) BaseSystem(CoreLib.VOTE_BOOTH, _core) {}

    function vote(
        uint256 _propID,
        bytes32 _vote
    )
        external 
        returns(bool)
    {
        // TODO call prop specified library (address from core)
        
        // TODO store consensus after vote (might want this to be external contract per vote type)
        
        return true;
    }
    
    // QS make voting library for simple majority 
    // QS make voting library for simple quorum 
}