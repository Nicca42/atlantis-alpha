// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

// Use ERC20Votes for snapshot token balances 

contract VoteWeight {

    function getVoteWeight(
        uint256 _propID,
        address _voter
    )
        external 
        returns(uint256)
    {
        // TODO if first check for a prop make snapshot 

        // TODO maybe use library for vote weight? Then can have multiple

        return 0;
    }
}