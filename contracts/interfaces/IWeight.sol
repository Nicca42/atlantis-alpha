// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IWeight {
    function getVoteWeight(uint256 _propID, address _voter)
        external
        returns (uint256);

    function getTotalWeight(uint256 _propID) external view returns (uint256);
}