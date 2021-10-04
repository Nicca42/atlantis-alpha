// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./BaseSystem.sol";

// Use ERC20Votes for snapshot token balances 

contract VoteWeight is BaseSystem {

    constructor(address _core) BaseSystem(CoreLib.VOTE_WEIGHT, _core) {}

    function initialise(
        address _govToken,
        address _repToken
    ) external 
    {
        // QS real init

        // QS turn into registry like voting booth
    }

    function getVoteWeight(
        uint256 _propID,
        address _voter
    )
        external 
        returns(uint256)
    {
        // TODO if first check for a prop make snapshot 
        // NOTE does it not make more sense to do the snapshot here??

        // TODO maybe use library for vote weight? Then can have multiple

        return 1;
    }
}