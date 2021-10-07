// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "../BaseSystem.sol";
import "./IVoteType.sol";

contract SimpleMajority is BaseSystem, IVoteType {
    //--------------------------------------------------------------------------
    // STATE
    //--------------------------------------------------------------------------

    struct Votes {
        uint256 weightFor;
        uint256 weightAgainst;
        mapping(address => bool) hasVoted;
        uint256 voterTurnout;
    }

    mapping(uint256 => Votes) private voteCount_;

    //--------------------------------------------------------------------------
    // MODIFIER
    //--------------------------------------------------------------------------

    modifier onlyVotingBooth() {
        address votingBooth = core_.getInstance(CoreLib.VOTE_BOOTH);
        require(votingBooth == msg.sender, "Voting Type: Only Voting Booth");
        _;
    }

    //--------------------------------------------------------------------------
    // CONSTRUCTOR
    //--------------------------------------------------------------------------

    constructor(address _core, address _timer)
        BaseSystem(keccak256("VOTE_TYPE_SIMPLE_MAJORITY"), _core, _timer)
    {}

    //--------------------------------------------------------------------------
    // VIEW & PURE FUNCTIONS
    //--------------------------------------------------------------------------

    /**
     *  @param  _ballot Bytes of user vote
     * @return  bool the decoded vote
     * @notice  This function iss separate from the vote function to allow the
     *          vote function to throw a more accurate revert message if the
     *          ballot is incorrectly formatted.
     */
    function decodeCastBallot(bytes memory _ballot)
        external
        pure
        returns (bool)
    {
        return abi.decode(_ballot, (bool));
    }

    function encodeBallot(bool _for) external pure returns (bytes memory) {
        return abi.encode(_for);
    }

    function getCurrentVote(uint256 _propID) external view returns(
        uint256 weightFor,
        uint256 weightAgainst,
        uint256 voterTurnout
    ) {
        weightFor = voteCount_[_propID].weightFor;
        weightAgainst = voteCount_[_propID].weightAgainst;
        voterTurnout = voteCount_[_propID].voterTurnout;
    }
    
    function hasVoted(uint256 _propID, address _voter) external view returns(bool) {
        return voteCount_[_propID].hasVoted[_voter];
    }

    function consensusReached(uint256 _propID)
        external
        view
        override
        returns (bool reached, bool votePassed)
    {
        IWeight weightImplementation = IWeight(
            core_.getInstance(CoreLib.VOTE_WEIGHT)
        );

        uint256 totalWeight = weightImplementation.getTotalWeight(_propID);

        uint256 allVotedWeight = voteCount_[_propID].weightFor +
            voteCount_[_propID].weightAgainst;

        if (totalWeight / 2 > allVotedWeight) {
            // Not enough weight has voted for simple majority
            return (false, false);
        } else if (
            voteCount_[_propID].weightFor > voteCount_[_propID].weightAgainst
        ) {
            return (true, true);
        }
        return (true, false);
    }

    //--------------------------------------------------------------------------
    // PUBLIC & EXTERNAL FUNCTIONS
    //--------------------------------------------------------------------------

    function vote(
        uint256 _propID,
        bytes memory _vote,
        address _voter
    ) external override onlyVotingBooth returns (bool) {
        require(
            !voteCount_[_propID].hasVoted[_voter],
            "Booth: Voter Has voted for prop"
        );
        // NOTE if using a snapshot a user would be able to change their vote

        voteCount_[_propID].hasVoted[_voter] = true;
        voteCount_[_propID].voterTurnout += 1;

        IWeight weightImplementation = IWeight(
            core_.getInstance(CoreLib.VOTE_WEIGHT)
        );

        uint256 voteWeight = weightImplementation.getVoteWeight(
            _propID,
            _voter
        );

        try this.decodeCastBallot(_vote) returns (bool castVoteFor) {
            if (castVoteFor) {
                voteCount_[_propID].weightFor += voteWeight;
            } else {
                voteCount_[_propID].weightAgainst += voteWeight;
            }
        } catch {
            require(false, "Vote incorrectly formatted");
        }

        return true;
    }

    // TODO call proposal with first vote (maybe votebooth calls?)
    //      to update state and ensure voting only happens in valid period.

}
