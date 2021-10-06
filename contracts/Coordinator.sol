// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./BaseSystem.sol";

interface IProp {
    function getPropVotables(uint256 _propID)
        external
        view
        returns (
            PropState state,
            uint256 voteStart,
            uint256 voteEnd,
            bool executedOrCanceled
        );
}

contract Coordinator is BaseSystem {
    //--------------------------------------------------------------------------
    // STATE
    //--------------------------------------------------------------------------

    // QS move to base
    enum PropState {
        NotCreated,
        Created,
        ActiveVoting,
        Canceled,
        Defeated,
        Succeeded,
        Queued,
        Expired,
        Executed
    }

    mapping(address => mapping(bytes32 => address)) private subSystems_;

    //--------------------------------------------------------------------------
    // CONSTRUCTOR
    //--------------------------------------------------------------------------

    constructor(address _core) BaseSystem(CoreLib.COORD, _core) {}

    //--------------------------------------------------------------------------
    // VIEW & PURE FUNCTIONS
    //--------------------------------------------------------------------------

    /**
     * @param   _propID ID of the executable to check.
     * @notice  This function will check that the specified proposal has reached
     *          quorum, and that it has passed. If the proposal has not reached
     *          quorum or has not passed this will return false.
     * @dev     The reason we use Exe IDs here and not Prop IDs is that
     *          executables may be valid for execution outside of a proposal
     *          (e.g an approved recurring payment). If the exe is tied to a
     *          proposal the coordinator will be able to look up and verify it's
     *          executable status.
     */
    function isExecutable(bytes32 _exeID) external view returns (bool) {
        IProp propInstance = IProp(core_.getInstance(CoreLib.PROP));

        (
            PropState state,
            uint256 voteStart,
            uint256 voteEnd,
            bool executedOrCanceled
        ) = propInstance.getPropVotables(_propID);

        if (
            // State is queued
            state == PropState.Queued &&
            // AND vote end has passed
            voteEnd > block.timestamp &&
            // AND prop has not been executed or canceled
            !executedOrCanceled
        ) {
            return true;
        }
        return false;
    }

    function isVotable(uint256 _propID) external view returns (bool) {
        IProp propInstance = IProp(core_.getInstance(CoreLib.PROP));

        (
            PropState state,
            uint256 voteStart,
            uint256 voteEnd,
            bool executedOrCanceled
        ) = propInstance.getPropVotables(_propID);

        if (
            // State is created or active
            state == PropState.Created ||
            // AND vote start has passed
            // AND vote end has not passed
            // AND prop has not been executed or canceled
            (state == PropState.ActiveVoting &&
                voteStart >= block.timestamp &&
                voteEnd <= block.timestamp &&
                !executedOrCanceled)
        ) {
            return true;
        }
        return false;
    }

    function getSubSystem(address _system, bytes32 _subIdentifier)
        external
        view
        returns (address)
    {
        return subSystems_[_system][_subIdentifier];
    }

    //--------------------------------------------------------------------------
    // PUBLIC & EXTERNAL FUNCTIONS
    //--------------------------------------------------------------------------

    function addSubSystem(
        bytes32 _subIdentifier, 
        address _subImplementation
    )
        external
    {
        bytes32 identifier = BaseSystem(msg.sender).IDENTIFIER();
        address systemRegistered = core_.getInstance(identifier);

        require(msg.sender == systemRegistered, "Coord: Incorrect ID for sub");

        subSystems_[msg.sender][_subIdentifier] = _subImplementation;
    }

    // function execute
    // TODO the core calls when it is going to execute. Will check execution
    // is valid, as well as updating the state to be executed. 
}
