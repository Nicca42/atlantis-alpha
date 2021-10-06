// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./BaseSystem.sol";

// QS move to base
interface IExe {
    function getExe(bytes32 _exeID)
        external
        view
        returns (
            address[] memory targets,
            bytes[] memory callData,
            uint256[] memory values
        );

    function createPropExe(
        uint256 _propID,
        bytes32 _exeID,
        string memory _description
    ) external returns (bytes32 propExeID);
}

interface ICoord {
    function getSubSystem(address _system, bytes32 _subIdentifier)
        external
        view
        returns (address);
}

contract Proposals is BaseSystem {

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

    // QS replace system wide with this
    enum PropStatus {
        NO_PROP,
        CREATED,
        VOTING,
        EXPIRED,
        DEFEATED,
        QUEUED,
        EXECUTED
        // Only successful props can be queued, no need for a state. 
    }

    struct Prop {
        string description;
        address voteType;
        bytes32 exeID;
        PropState state;
        uint256 voteStart;
        uint256 voteEnd;
        bool executedOrCanceled;
    }

    mapping(uint256 => Prop) private props_;
    // Exe IDs to related props
    mapping(bytes32 => uint256) private exeToProp_;

    uint256 private propIDCounter_;

    uint256 private voteStartDelay_;
    uint256 private voteEndDelay_;
    uint256 private minDelay_;

    //--------------------------------------------------------------------------
    // EVENTS
    //--------------------------------------------------------------------------

    event NewProposal(uint256 indexed propID, address voteType, bytes32 exeID);

    modifier onlyCoord() {
        address coordInstance = core_.getInstance(CoreLib.COORD);
        require(
            msg.sender == coordInstance,
            "Prop: Only coord can call"
        );
        _;
    }

    //--------------------------------------------------------------------------
    // CONSTRUCTOR
    //--------------------------------------------------------------------------

    constructor(address _core) BaseSystem(CoreLib.PROPS, _core) {}

    //--------------------------------------------------------------------------
    // VIEW & PURE FUNCTIONS
    //--------------------------------------------------------------------------

    function getVoteType(uint256 _propID) external view returns (address) {
        return props_[_propID].voteType;
    }

    function getExeOfProp(uint256 _propID) external view returns(bytes32) {
        return props_[_propID].exeID;
    }

    function getPropOfExe(bytes32 _exeID) external view returns(uint256) {
        return exeToProp_[_exeID];
    }

    function getProposalInfo(uint256 _propID) external view returns(
        string memory description,
        address voteType,
        bytes32 exeID,
        PropState state,
        uint256 voteStart,
        uint256 voteEnd,
        bool executedOrCanceled
    ) {
        return (
            props_[_propID].description,
            props_[_propID].voteType,
            props_[_propID].exeID,
            props_[_propID].state,
            props_[_propID].voteStart,
            props_[_propID].voteEnd,
            props_[_propID].executedOrCanceled
        );
    }

    function getPropVotables(uint256 _propID) external view returns(
        PropState state,
        uint256 voteStart,
        uint256 voteEnd,
        bool executedOrCanceled
    ) {
        return(
            props_[_propID].state,
            props_[_propID].voteStart,
            props_[_propID].voteEnd,
            props_[_propID].executedOrCanceled
        );
    }

    //--------------------------------------------------------------------------
    // PUBLIC & EXTERNAL FUNCTIONS
    //--------------------------------------------------------------------------

    function createPropWithExe(
        string calldata _description,
        bytes32 _voteTypeID,
        bytes32 _exeID
    ) external returns (uint256 propID) {
        IExe exeInstance = IExe(core_.getInstance(CoreLib.EXE));
        ICoord coordInstance = ICoord(core_.getInstance(CoreLib.COORD));

        propIDCounter_ += 1;

        propID = propIDCounter_;

        address voteType = coordInstance.getSubSystem(
            core_.getInstance(CoreLib.VOTE_BOOTH),
            _voteTypeID
        );

        require(voteType != address(0), "Prop: Invalid vote type");

        string memory newDescription = string(abi.encodePacked(
            propID, 
            _exeID,
            block.timestamp
        ));

        bytes32 propExeID = exeInstance.createPropExe(
            propID,
            _exeID,
            newDescription
        );

        require(propExeID != bytes32(0), "Prop: Exe does not exist");
        require(
            exeToProp_[propExeID] == 0,
            "Prop: Exe ID already associated"
        );

        uint256 voteStart = block.timestamp + voteStartDelay_;

        props_[propID] = Prop({
            description: _description,
            voteType: voteType,
            exeID: propExeID,
            state: PropState.Created,
            voteStart: voteStart,
            voteEnd: voteStart + voteEndDelay_,
            executedOrCanceled: false
        });
        exeToProp_[propExeID] = propID;

        emit NewProposal(propID, voteType, propExeID);

        // TODO proposal snapshot in vote weight
    }

    //--------------------------------------------------------------------------
    // ONLY CORE
    //
    // Below functions can only be called by this contract. These functions can
    // only be executed by successfully running an executable through the
    // `execute` function.

    /**
     * @param   _newMin The new minimum delay for normal proposals.
     * @notice  This minimum delay counts for both voting starting after a
     *          proposal is proposed, as well as how long the delay is after it
     *          has started till voting closes. Only the core can modify.
     * @dev     These mins are time stamps. The min delay cannot be smaller than
     *          15 (safe minimum).
     */
    function updateMinDelay(uint256 _newMin) external onlyCore {
        require(_newMin > 15, "Prop: min cannot be 0");
        minDelay_ = _newMin;
    }

    /**
     * @param   _startDelay The delay before voting can start on a proposal.
     * @param   _endDelay The delay after voting starts for voting to close.
     * @notice  This minimum delay counts for both voting starting after a
     *          proposal is proposed, as well as how long the delay is after it
     *          has started till voting closes. Only the core can modify.
     * @dev     These mins are time stamps. The min delay cannot be smaller than
     *          15 (safe minimum).
     */
    function updateDelays(
        uint256 _startDelay, 
        uint256 _endDelay
    )
        external
        onlyCore
    {
        require(
            _startDelay >= minDelay_ && _endDelay >= minDelay_,
            "Prop: delays cannot be 0"
        );

        voteStartDelay_ = _startDelay;
        voteEndDelay_ = _endDelay;
    }


    //--------------------------------------------------------------------------
    // ONLY COORDINATOR
    //
    // Below functions can only be called by the coordinator.

    /**
     * @param   _propID ID of the prop.
     * @notice  Updates the proposals state to Expired. Only the coordinator 
     *          can call this function. 
     *          A proposal expires if it does not reach the minimum consensus 
     *          specifications before the vote window expires. 
     */
    function propExpire(uint256 _propID) external onlyCoord {
        require(
            props_[_propID].state == PropState.ActiveVoting,
            "Prop: Invalid state movement"
        );

        props_[_propID].state = PropState.Expired;
    }

    /**
     * @param   _propID ID of the prop.
     * @notice  Updates the proposals state to Defeated. Only the coordinator 
     *          can call this function. 
     *          A proposal is defeated if it reaches the minimum consensus 
     *          specifications but is voted against. 
     */
    function propDefeated(uint256 _propID) external onlyCoord {
        require(
            props_[_propID].state == PropState.ActiveVoting,
            "Prop: Invalid state movement"
        );

        props_[_propID].state = PropState.Defeated;
    }

    /**
     * @param   _propID ID of the prop.
     * @notice  Updates the proposals state to Queued. Only the coordinator 
     *          can call this function. 
     *          A proposal is queued if it reaches the minimum consensus 
     *          specifications and is voted for. Once queued a proposal can be
     *          executed. If a proposal does not have an executable, it can 
     *          still be "executed" to update the state in accordance. 
     */
    function propQueued(uint256 _propID) external onlyCoord {
        require(
            props_[_propID].state == PropState.ActiveVoting,
            "Prop: Invalid state movement"
        );

        props_[_propID].state = PropState.Queued;
    }

    /**
     * @param   _propID ID of the prop.
     * @notice  Updates the proposals state to Executed. Only the coordinator 
     *          can call this function. 
     *          A proposal is executed if it reaches the minimum consensus 
     *          specifications, is voted for and then executed. If a proposal 
     *          has a related executable this executable will be run in the 
     *          context of the core. If there is no associated executable, the
     *          status of the proposal will be updated regardless. 
     */
    function propExecuted(uint256 _propID) external onlyCoord {
        require(
            props_[_propID].state == PropState.Queued,
            "Prop: Invalid state movement"
        );

        props_[_propID].state = PropState.Executed;
    }

}
