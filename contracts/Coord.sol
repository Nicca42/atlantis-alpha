// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract Coord {

    function isPropExecutable(uint256 _propID) external returns(bool, bytes32) {

        // TODO this fucntion checks with the voting booth if prop has passed

        // TODO if the prop has expired or anything like that this should then
        //      update the state to reflect that the proposal has failed consensus
        //      or expired. 

        return (true, bytes32(0));
    }
}