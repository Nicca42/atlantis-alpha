// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./BaseSystem.sol";

interface IProp {
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

    function getPropVotables(uint256 _propID)
        external
        view
        returns (
            PropState state,
            uint256 voteStart,
            uint256 voteEnd,
            bool executedOrCanceled
        );

    function getPropOfExe(bytes32 _exeID) external view returns(uint256);
}

contract Coordinator is BaseSystem {
    //--------------------------------------------------------------------------
    // STATE
    //--------------------------------------------------------------------------

    mapping(address => mapping(bytes32 => address)) private subSystems_;

    //--------------------------------------------------------------------------
    // CONSTRUCTOR
    //--------------------------------------------------------------------------

    constructor(address _core) BaseSystem(CoreLib.COORD, _core) {}

    //--------------------------------------------------------------------------
    // VIEW & PURE FUNCTIONS
    //--------------------------------------------------------------------------

    /**
     * @param   _exeID ID of the executable to check.
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
        IProp propInstance = IProp(core_.getInstance(CoreLib.PROPS));

        uint256 propID = propInstance.getPropOfExe(_exeID);

        // If prop does not exist for this exe then it is not executable
        if(propID == uint256(0)) {
            // FUTURE in later versions one might want to have a list of 
            //        pre-approved exes that can be executed on a recurring 
            //        basis (i.e monthly payments)/
            return false;
        }

        (
            IProp.PropState state,
            uint256 voteStart,
            uint256 voteEnd,
            bool executedOrCanceled
        ) = propInstance.getPropVotables(propID);

        if (
            // State is queued
            state == IProp.PropState.Queued &&
            // AND vote end has passed
            voteEnd > block.timestamp &&
            // AND prop has not been executed or canceled
            !executedOrCanceled
        ) {
            return true;
        }
        // Don't need to return false, will return false if not returning true.
    }

    function isVotable(uint256 _propID) external view returns (bool) {
        IProp propInstance = IProp(core_.getInstance(CoreLib.PROPS));

        (
            IProp.PropState state,
            uint256 voteStart,
            uint256 voteEnd,
            bool executedOrCanceled
        ) = propInstance.getPropVotables(_propID);

        if (
            // State is created or active
            state == IProp.PropState.Created || 
            state == IProp.PropState.ActiveVoting &&
            // AND vote start has passed
            voteStart >= block.timestamp &&
            // AND vote end has not passed
            voteEnd <= block.timestamp &&
            // AND prop has not been executed or canceled
            !executedOrCanceled
        ) {
            return true;
        }
        // Don't need to return false, will return false if not returning true.
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
