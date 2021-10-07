// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./BaseSystem.sol";
import "./openZeppelin/IERC20.sol";

// Use ERC20Votes for snapshot token balances

contract VoteWeight is BaseSystem, IWeight {
    //--------------------------------------------------------------------------
    // STATE
    //--------------------------------------------------------------------------

    IERC20 private govToken_;
    IERC20 private repToken_;

    //--------------------------------------------------------------------------
    // CONSTRUCTOR
    //--------------------------------------------------------------------------

    constructor(address _core, address _timer)
        BaseSystem(CoreLib.VOTE_WEIGHT, _core, _timer)
    {}

    function initialise(address _govToken, address _repToken)
        external
        initializer
    {
        govToken_ = IERC20(_govToken);
        repToken_ = IERC20(_repToken);

        // FUTURE turn into registry like voting booth
        // use library for vote weight? Then can have multiple
    }

    //--------------------------------------------------------------------------
    // VIEW & PURE FUNCTIONS
    //--------------------------------------------------------------------------

    /**
     * @param   _propID This lets the vote weight get the correct snapshot for
     *          each proposal.
     * @param   _voter Address of the voter.
     * @notice  The vote weight of the _voter is a simple equation of their
     *          governance and reputation token:
     *          vote_weight = (gov_token * rep_token) / 2
     */
    function getVoteWeight(uint256 _propID, address _voter)
        external
        view
        override
        returns (uint256)
    {
        // TODO if first check for a prop make snapshot
        // NOTE does it not make more sense to do the snapshot here??
        // Nope. Need to snapshot at proposal for flash loans :/

        uint256 voteWeight = govToken_.balanceOf(_voter) *
            repToken_.balanceOf(_voter);

        // return(voteWeight == 0 ? 0 : voteWeight / 2);
        if (voteWeight == 0) {
            return 0;
        } else {
            return voteWeight / 2;
        }
    }

    function getTotalWeight(uint256 _propID) external view override returns (uint256) {
        // TODO this should use the snapshot. Super insecure to do it like this
        return (govToken_.totalSupply() + repToken_.totalSupply() / 2);
    }
}
