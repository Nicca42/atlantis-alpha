// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract Proposals {

    function createProp(
        string calldata _description, 
        bytes32 _voteType,
        bytes32 _consensusType,
        bytes32 _exeID
    ) external returns(uint256 propID) {
        // TODO verify exe
            // get exe implementation from core 

        return 0;
    }

    // TODO proposal snapshot 


}