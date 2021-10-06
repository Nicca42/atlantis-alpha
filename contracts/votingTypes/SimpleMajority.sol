// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "../BaseSystem.sol";

interface IVoteWeight {
    function getVoteWeight(
        uint256 _propID,
        address _voter
    )
        external 
        returns(uint256);

    function getTotalWeight(uint256 _propID) external view returns(uint256);
}

contract SimpleMajority is BaseSystem {

    struct Votes {
        uint256 weightFor;
        uint256 weightAgainst;
        mapping(address => bool) hasVoted;
        uint256 voterTurnout;
    }
    
    mapping(uint256 => Votes) private voteCount_;

    modifier onlyVotingBooth() {
        address votingBooth = core_.getInstance(CoreLib.VOTE_BOOTH);
        require(
            votingBooth == msg.sender,
            "Voting Type: Only Voting Booth"          
        );
        _;
    }
    constructor(address _core)
        BaseSystem(keccak256("VOTE_TYPE_SIMPLE_MAJORITY"), _core)
    {}

    /**
     *  @param  _ballot Bytes of user vote
     * @return  bool the decoded vote
     * @notice  This function iss separate from the vote function to allow the
     *          vote function to throw a more accurate revert message if the
     *          ballot is incorrectly formatted. 
     */
    function decodeCastBallot(bytes memory _ballot) external pure returns (bool) {
        // NOTE in less restrictive data types verification will need to be 
        //      performed on decoded data as incorrect castings can occur 
        //      without causing errors. 
        return abi.decode(_ballot, (bool));
    }

    function encodeBallot(bool _for) external pure returns(bytes memory) {
        return abi.encodePacked(_for);
    }

    function vote(
        uint256 _propID,
        bytes memory _vote,
        address _voter
    ) external onlyVotingBooth returns (bool) {
        require(
            !voteCount_[_propID].hasVoted[_voter],
            "Booth: Voter Has voted for prop"
        );
        // NOTE if using a snapshot a user would be able to change their vote

        voteCount_[_propID].hasVoted[_voter] = true;
        voteCount_[_propID].voterTurnout += 1;

        IVoteWeight weightImplementation = IVoteWeight(
            core_.getInstance(CoreLib.VOTE_WEIGHT)
        );
        
        uint256 voteWeight = weightImplementation.getVoteWeight(_propID, _voter);

        try this.decodeCastBallot(_vote) returns (bool castVoteFor) {
            if(castVoteFor) {
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

    enum QuorumStatus {
        InsufficientParticipation,
        VotePassed,
        VoteFailed
    }

    function _quorumReached(uint256 _propID) internal returns(QuorumStatus) {
        IVoteWeight weightImplementation = IVoteWeight(
            core_.getInstance(CoreLib.VOTE_WEIGHT)
        );

        uint256 totalWeight = weightImplementation.getTotalWeight(_propID);

        uint256 allVotedWeight = voteCount_[_propID].weightFor +
            voteCount_[_propID].weightAgainst;
        
        if(totalWeight/2 > allVotedWeight) {
            // Not enough weight has voted for simple majority
            return QuorumStatus.InsufficientParticipation;
        } else if(
            voteCount_[_propID].weightFor > voteCount_[_propID].weightAgainst
        ) {
            return QuorumStatus.VotePassed;
        }
        return QuorumStatus.VoteFailed;
    }
}
