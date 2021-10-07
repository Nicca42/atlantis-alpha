// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IBooth {
    function consensusReached(uint256 _propID)
        external
        view
        returns (bool reached, bool votePassed);
}