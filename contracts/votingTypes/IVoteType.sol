// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;
interface IVoteType {
    function vote(uint256 _propID, bytes memory _vote, address _voter) external returns(bool);
}