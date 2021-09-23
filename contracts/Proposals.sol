// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./CoreLib.sol";

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

interface ICore {
    function getInstance(bytes32 _key) external view returns (address);

    function IDENTIFIER() external view returns (bytes32);
}

contract Proposals {
    ICore private core_;

    uint256 private propIDCounter_;

    struct Prop {
        string description;
        bytes32 voteType;
        bytes32 consensusType;
        bytes32 exeID;
    }

    mapping(uint256 => Prop) private props_;

    // TODO this is probably going to need to an initialisers
    constructor(address _core) {
        core_ = ICore(_core);
        // NOTE this does not protect from malformed core modules, it prevents
        //      non-malicious error deployments.
        require(
            core_.IDENTIFIER() == bytes32(keccak256("CORE")),
            "Core: identifier incorrect"
        );
    }

    function createPropWithExe(
        string calldata _description,
        bytes32 _voteType,
        bytes32 _consensusType,
        bytes32 _exeID
    ) external returns (uint256 propID) {
        IExe exeInstance = IExe(core_.getInstance(CoreLib.EXE));

        propIDCounter_ += 1;

        propID = propIDCounter_;

        bytes32 propExeID = exeInstance.createPropExe(propID, _exeID);

        require(propExeID != bytes32(0), "Core: Exe does not exist");

        props_[propID] = Prop({
            description: _description,
            voteType: _voteType,
            consensusType: _consensusType,
            exeID: propExeID
        });
    }

    // TODO proposal snapshot
}
