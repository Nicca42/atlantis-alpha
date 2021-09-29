// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./BaseSystem.sol";

// Use ERC20Votes for delegation of votes
// GovernerVotes for where to hook into token 

interface IProp {
    function getVoteType(uint256 _propID) external view returns(address);
}

interface IVoteType {
    function vote(uint256 _propID, bytes memory _vote, address _voter) external returns(bool);
}

contract VotingBooth is BaseSystem {

    //--------------------------------------------------------------------------
    // STATE
    //--------------------------------------------------------------------------

    struct VoteType {
        bytes32 typeId;
        string voteFormat;

    }

    mapping(address => VoteType) private voteTypes_;

    event VoteCast(
        address indexed voter,
        uint256 indexed propID,
        bytes vote
    );

    //--------------------------------------------------------------------------
    // CONSTRUCTOR
    //--------------------------------------------------------------------------

    constructor(
        address _core,
        address _initialVoteInstance,
        bytes32 _initialVoteType,
        string memory _voteFormat
    ) BaseSystem(CoreLib.VOTE_BOOTH, _core) {
        voteTypes_[_initialVoteInstance] = VoteType({
            typeId: _initialVoteType,
            voteFormat: _voteFormat
        });
    }

    function vote(
        uint256 _propID,
        bytes memory _vote
    )
        external 
        returns(bool)
    {
        IProp propInstance = IProp(core_.getInstance(CoreLib.PROPS));

        IVoteType voteType = IVoteType(propInstance.getVoteType(_propID));

        // QS call prop instance to ensure prop is votable 

        // QS ensure vote type is registered here. 

        emit VoteCast(
            msg.sender,
            _propID,
            _vote
        );

        return voteType.vote(_propID, _vote, msg.sender);
    }

    function addVoteType(
        bytes32 _voteType, 
        address _instance,
        string calldata _voteFormat
        ) external onlyCore() {
        voteTypes_[_instance] = VoteType({
            typeId: _voteType,
            voteFormat: _voteFormat
        });
    }
    
    // QS make voting library for simple majority 
    // QS make voting library for simple quorum 
}