// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./BaseSystem.sol";

contract Coordinator is BaseSystem, ICoord {

    //--------------------------------------------------------------------------
    // STATE
    //--------------------------------------------------------------------------

    mapping(address => mapping(bytes32 => address)) private subSystems_;

    //--------------------------------------------------------------------------
    // CONSTRUCTOR
    //--------------------------------------------------------------------------

    constructor(address _core, address _timer)
        BaseSystem(CoreLib.COORD, _core, _timer)
    {}

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
    function isExecutable(bytes32 _exeID) external view override returns (bool) {
        IProp propInstance = IProp(core_.getInstance(CoreLib.PROPS));

        uint256 propID = propInstance.getPropOfExe(_exeID);

        // If prop does not exist for this exe then it is not executable
        if (propID == uint256(0)) {
            // FUTURE in later versions one might want to have a list of
            //        pre-approved exes that can be executed on a recurring
            //        basis (i.e monthly payments)/
            return false;
        }

        (
            IProp.PropStatus state,
            ,
            uint256 voteEnd,
            bool executedOrCanceled
        ) = propInstance.getPropVotables(propID);

        if (
            // State is queued
            state == IProp.PropStatus.QUEUED &&
            // AND vote end has passed
            voteEnd < getCurrentTime() &&
            // AND prop has not been executed or canceled
            !executedOrCanceled
        ) {
            return true;
        }
        // Don't need to return false, will return false if not returning true.
    }

    function setExecute(bytes32 _exeID) external override onlyCore {
        IProp propInstance = IProp(core_.getInstance(CoreLib.PROPS));

        uint256 propID = propInstance.getPropOfExe(_exeID);

        // If prop does not exist for this exe then it is not executable
        require(propID != uint256(0), "Coord: No linked prop");
        // FUTURE in later versions one might want to have a list of
        //        pre-approved exes that can be executed on a recurring
        //        basis (i.e monthly payments)/

        (
            IProp.PropStatus state,
            ,
            uint256 voteEnd,
            bool spent
        ) = propInstance.getPropVotables(propID);

        require(
            // State is queued
            state == IProp.PropStatus.QUEUED &&
            // AND vote end has passed
            voteEnd <= getCurrentTime() &&
            // AND prop has not been executed or canceled
            !spent,
            "Coord: exe not executable"
        );

        propInstance.propExecuted(propID);
    }

    function isVotable(uint256 _propID) external view override returns (bool) {
        IProp propInstance = IProp(core_.getInstance(CoreLib.PROPS));

        (
            IProp.PropStatus state,
            uint256 voteStart,
            uint256 voteEnd,
            bool executedOrCanceled
        ) = propInstance.getPropVotables(_propID);

        if (
            // State is created or active
            (state == IProp.PropStatus.CREATED ||
                state == IProp.PropStatus.VOTING) &&
            // AND vote start has passed
            voteStart <= getCurrentTime() &&
            // AND vote end has not passed
            voteEnd >= getCurrentTime() &&
            // AND prop has not been executed or canceled
            !executedOrCanceled
        ) {
            return true;
        }
        // Don't need to return false, will return false if not returning true.
    }

    function voting(uint256 _propID) external override {
        IProp propInstance = IProp(core_.getInstance(CoreLib.PROPS));
        IBooth boothInstance = IBooth(core_.getInstance(CoreLib.VOTE_BOOTH));

        (
            IProp.PropStatus state,
            uint256 voteStart,
            uint256 voteEnd,
            bool executedOrCanceled
        ) = propInstance.getPropVotables(_propID);
        
        require(
            IBooth(msg.sender) == boothInstance,
            "Coord: Only booth can call"
        );
        require(
            // State is created or active
            (state == IProp.PropStatus.CREATED ||
                state == IProp.PropStatus.VOTING) &&
            // AND vote start has passed
            voteStart <= getCurrentTime() &&
            // AND vote end has not passed
            voteEnd >= getCurrentTime() &&
            // AND prop has not been executed or canceled
            !executedOrCanceled,
            "Coord: prop not votable"
        );

        // If the state has not been set to voting this sets it to voting.
        if(state == IProp.PropStatus.CREATED) {
            propInstance.propVoting(_propID);
        }
    }

    function getSubSystem(address _system, bytes32 _subIdentifier)
        external
        view
        override
        returns (address)
    {
        return subSystems_[_system][_subIdentifier];
    }

    //--------------------------------------------------------------------------
    // PUBLIC & EXTERNAL FUNCTIONS
    //--------------------------------------------------------------------------

    function addSubSystem(bytes32 _subIdentifier, address _subImplementation)
        external
        override
    {
        bytes32 identifier = BaseSystem(msg.sender).IDENTIFIER();
        address systemRegistered = core_.getInstance(identifier);

        require(msg.sender == systemRegistered, "Coord: Incorrect ID for sub");

        subSystems_[msg.sender][_subIdentifier] = _subImplementation;
    }

    // function execute
    // TODO the core calls when it is going to execute. Will check execution
    // is valid, as well as updating the state to be executed.

    function queueProposal(uint256 _propID) external {
        IBooth boothInstance = IBooth(core_.getInstance(CoreLib.VOTE_BOOTH));
        IProp propInstance = IProp(core_.getInstance(CoreLib.PROPS));

        (
            , , uint256 voteEnd, bool executedOrCanceled
        ) = propInstance.getPropVotables(_propID);

        require(
            voteEnd >= getCurrentTime() && !executedOrCanceled,
            "Coord: voting active or executed"
        );

        (bool reached, bool votePassed) = boothInstance.consensusReached(
            _propID
        );

        if (!reached) {
            // Proposal expired without reaching consensus
            propInstance.propExpire(_propID);
        } else if (!votePassed) {
            // Proposal was defeated
            propInstance.propDefeated(_propID);
        } else {
            // Proposal succeeded and can be queued
            propInstance.propQueued(_propID);
        }
    }
}
