// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./BaseSystem.sol";

interface IExe {
    function getExe(bytes32 _exeID)
        external
        view
        returns (
            address[] memory targets,
            bytes[] memory callData,
            uint256[] memory values
        );

    function createPropExe(uint256 _propID, bytes32 _exeID)
        external
        returns (bytes32 propExeID);
}

contract Proposals is BaseSystem {

    uint256 private propIDCounter_;

    struct Prop {
        string description;
        address voteType;
        bytes32 consensusType;
        bytes32 exeID;
    }

    mapping(uint256 => Prop) private props_;

    event NewProposal(
        uint256 indexed propID,
        address voteType,
        bytes32 exeID
    );

    // TODO this is probably going to need to an initialisers
    constructor(address _core) BaseSystem(CoreLib.PROPS, _core) {}

    function getVoteType(uint256 _propID) external view returns(address) {
        return props_[_propID].voteType;
    }

    function createPropWithExe(
        string calldata _description,
        address _voteType,
        bytes32 _consensusType,
        bytes32 _exeID
    ) external returns (uint256 propID) {
        IExe exeInstance = IExe(core_.getInstance(CoreLib.EXE));

        propIDCounter_ += 1;

        propID = propIDCounter_;

        bytes32 propExeID = exeInstance.createPropExe(propID, _exeID);

        require(propExeID != bytes32(0), "Prop: Exe does not exist");

        props_[propID] = Prop({
            description: _description,
            voteType: _voteType,
            consensusType: _consensusType,
            exeID: propExeID
        });

        emit  NewProposal(
            propID,
            _voteType,
            _exeID
        );
    }

    // TODO proposal snapshot
}
