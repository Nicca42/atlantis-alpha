// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./BaseSystem.sol";

// TODO Use ERC20Votes for delegation of votes
// TODO GovernerVotes for where to hook into token

contract VotingBooth is BaseSystem, IBooth {
    //--------------------------------------------------------------------------
    // STATE
    //--------------------------------------------------------------------------

    struct VoteType {
        bytes32 typeId;
        string voteFormat;
    }

    mapping(address => VoteType) private voteTypes_;

    //--------------------------------------------------------------------------
    // EVENTS
    //--------------------------------------------------------------------------

    event VoteCast(address indexed voter, uint256 indexed propID, bytes vote);

    //--------------------------------------------------------------------------
    // CONSTRUCTOR
    //--------------------------------------------------------------------------

    constructor(address _core, address _timer)
        BaseSystem(CoreLib.VOTE_BOOTH, _core, _timer)
    {}

    function initialise(
        address _initialVoteInstance,
        bytes32 _initialVoteType,
        string memory _voteFormat
    ) external initializer {
        _addVoteType(_initialVoteType, _initialVoteInstance, _voteFormat);
    }

    //--------------------------------------------------------------------------
    // VIEW & PURE FUNCTIONS
    //--------------------------------------------------------------------------

    function getVoteType(address _instance) external view returns (bytes32) {
        return voteTypes_[_instance].typeId;
    }

    function consensusReached(uint256 _propID)
        external
        view
        override
        returns (bool reached, bool votePassed)
    {
        IProp propInstance = IProp(core_.getInstance(CoreLib.PROPS));

        IVoteType voteType = IVoteType(propInstance.getVoteType(_propID));

        return voteType.consensusReached(_propID);
    }

    //--------------------------------------------------------------------------
    // PUBLIC & EXTERNAL FUNCTIONS
    //--------------------------------------------------------------------------

    function vote(uint256 _propID, bytes memory _vote) external {
        ICoord cordInstance = ICoord(core_.getInstance(CoreLib.COORD));

        IProp propInstance = IProp(core_.getInstance(CoreLib.PROPS));
        IVoteType voteType = IVoteType(propInstance.getVoteType(_propID));

        require(
            this.getVoteType(address(voteType)) != bytes32(0),
            "Booth: Invalid vote type/prop"
        );

        cordInstance.voting(_propID);

        emit VoteCast(msg.sender, _propID, _vote);

        require(
            voteType.vote(_propID, _vote, msg.sender),
            "Booth: Vote failed"
        );
    }

    function addVoteType(
        bytes32 _voteType,
        address _instance,
        string memory _voteFormat
    ) external onlyCore {
        _addVoteType(_voteType, _instance, _voteFormat);
    }

    //--------------------------------------------------------------------------
    // PRIVATE & INTERNAL FUNCTIONS
    //--------------------------------------------------------------------------

    function _addVoteType(
        bytes32 _voteType,
        address _instance,
        string memory _voteFormat
    ) internal {
        voteTypes_[_instance] = VoteType({
            typeId: _voteType,
            voteFormat: _voteFormat
        });

        ICoord coordInstance = ICoord(core_.getInstance(CoreLib.COORD));

        coordInstance.addSubSystem(_voteType, _instance);
    }
}
