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

    function createPropExe(uint256 _propID, bytes32 _exeID, string memory _description)
        external
        returns (bytes32 propExeID);
}

interface ICoord {
    function getSubSystem(address _system, bytes32 _subIdentifier) external view returns(address);
}

contract Proposals is BaseSystem {

    uint256 private propIDCounter_;

    struct Prop {
        string description;
        address voteType;
        bytes32 exeID;
    }

    mapping(uint256 => Prop) private props_;

    event NewProposal(
        uint256 indexed propID,
        address voteType,
        bytes32 exeID
    );

    constructor(address _core) BaseSystem(CoreLib.PROPS, _core) {}

    function getVoteType(uint256 _propID) external view returns(address) {
        return props_[_propID].voteType;
    }

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

        require(
            voteType != address(0),
            "Prop: Invalid vote type"
        );

        string memory newDescription = string(
            abi.encodePacked(
                propID,
                _exeID
            )  
        );

        bytes32 propExeID = exeInstance.createPropExe(
            propID, 
            _exeID, 
            newDescription
        );

        require(propExeID != bytes32(0), "Prop: Exe does not exist");

        props_[propID] = Prop({
            description: _description,
            voteType: voteType,
            exeID: propExeID
        });

        emit  NewProposal(
            propID,
            voteType,
            propExeID
        );
    }

    // TODO proposal snapshot
}
