// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

// import "./test/Timer.sol";
// import "./openZeppelin/Token.sol";
import "./Core.sol";
import "./Coordinator.sol";
import "./Executables.sol";
import "./Proposals.sol";
import "./VotingBooth.sol";
import "./VoteWeight.sol";
import "./votingTypes/SimpleMajority.sol";

contract Factory {

    struct Dao {
        address core;
        address coord;
        address exe;
        address prop;
        address booth;
        address weight;
        address simpleMaj;
    }

    Dao public dao;

    function deployBasicDao(address _timer) external {
        // address timer = address(new Timer());
        // dao.govToken = address(new Token("Gov", "GOV"));
        // dao.repToken = address(new Token("Rep", "REP"));
        dao.core = address(new Core());
        dao.coord = address(new Coordinator(dao.core, _timer));
        dao.exe = address(new Executables(dao.core, _timer));
        dao.prop = address(new Proposals(dao.core, _timer));
        dao.booth = address(new VotingBooth(dao.core, _timer));
        dao.weight = address(new VoteWeight(dao.core, _timer));
        dao.simpleMaj = address(new SimpleMajority(dao.core, _timer));
    }

    function initDao(address _gov, address _rep) external {
        Core(dao.core).initialise(
            dao.coord,
            dao.exe,
            dao.prop,
            dao.weight,
            dao.booth
        );

        VotingBooth(dao.booth).initialise(
            dao.simpleMaj,
            keccak256("VOTE_TYPE_SIMPLE_MAJORITY"),
            "bool"
        );

        VoteWeight(dao.weight).initialise(
            _gov,
            _rep
        );

        Proposals(dao.prop).initialise(
            15,
            86400,
            604800
        );
    }
}