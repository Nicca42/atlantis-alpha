// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IProp {
    function getVoteType(uint256 _propID) external view returns (address);

    enum PropStatus {
        NO_PROP,
        CREATED,
        VOTING,
        QUEUED,
        EXECUTED,
        EXPIRED,
        DEFEATED
        // Only successful props can be queued, no need for a state.
    }

    function getPropVotables(uint256 _propID)
        external
        view
        returns (
            PropStatus state,
            uint256 voteStart,
            uint256 voteEnd,
            bool executedOrCanceled
        );

    function getPropOfExe(bytes32 _exeID) external view returns (uint256);

    function propVoting(uint256 _propID) external;

    function propExpire(uint256 _propID) external;

    function propDefeated(uint256 _propID) external;

    function propQueued(uint256 _propID) external;

    function propExecuted(uint256 _propID) external;
}