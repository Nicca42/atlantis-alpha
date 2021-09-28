// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./BaseSystem.sol";

contract VoteStorage is BaseSystem {
    // TODO make registry for vote types & consensus types. Need to be careful
    //      about design to make sure it is highly extendable but protects 
    //      against votes getting lost with upgrades. 

    // function addVoteType(bytes32 _typeID) external 

    constructor(address _core) BaseSystem(CoreLib.VOTE_STORAGE, _core) {}
}