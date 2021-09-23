// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./CoreLib.sol";

interface ICore {
    function getInstance(bytes32 _key) external view returns (address);

    function IDENTIFIER() external view returns (bytes32);
}

contract Executables {
    ICore private core_;

    struct Exe {
        address[] targets;
        uint256[] values;
        bytes[] callData;
        string description;
        address creator;
    }

    mapping(bytes32 => Exe) private dotExe_;

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

    function getExe(bytes32 _exeID)
        external
        view
        returns (
            address[] memory targets,
            bytes[] memory callData,
            uint256[] memory values
        )
    {
        targets = dotExe_[_exeID].targets;
        callData = dotExe_[_exeID].callData;
        values = dotExe_[_exeID].values;
    }

    function getExeInfo(bytes32 _exeID)
        external
        view
        returns (
            address[] memory targets,
            bytes[] memory callData,
            uint256[] memory values,
            string memory description,
            address creator
        )
    {
        targets = dotExe_[_exeID].targets;
        callData = dotExe_[_exeID].callData;
        values = dotExe_[_exeID].values;
        description = dotExe_[_exeID].description;
        creator = dotExe_[_exeID].creator;
    }

    function getExeId(
        address[] memory _targets,
        uint256[] memory _values,
        bytes[] memory _callData,
        string memory _description
    ) public pure returns (bytes32) {
        return
            keccak256(abi.encode(_targets, _values, _callData, _description));
    }

    function createExe(
        address[] calldata _targets,
        string[] calldata _functionSignatures,
        bytes[] calldata _encodedParameters,
        uint256[] calldata _values,
        string calldata _description
    ) external returns (bytes32 exeID) {
        require(
            _targets.length == _functionSignatures.length &&
                _targets.length == _encodedParameters.length &&
                _targets.length == _values.length,
            "Exe: Array length mismatch"
        );

        bytes[] memory generatedCalldata = new bytes[](_targets.length);
        // Encodes the function signatures and parameters into calldata
        for (uint256 i = 0; i < _targets.length; i++) {
            generatedCalldata[i] = abi.encodePacked(
                bytes4(keccak256(bytes(_functionSignatures[i]))),
                _encodedParameters[i]
            );
        }

        exeID = getExeId(_targets, _values, generatedCalldata, _description);

        require(
            dotExe_[exeID].creator == address(0),
            "Exe: Exe ID already in use"
        );

        dotExe_[exeID] = Exe({
            targets: _targets,
            values: _values,
            callData: generatedCalldata,
            description: _description,
            creator: msg.sender
        });

        // TODO mint NFT token
    }

    function createPropExe(uint256 _propID, bytes32 _exeID)
        external
        returns (bytes32 propExeID)
    {
        require(
            core_.getInstance(CoreLib.PROPS) == msg.sender,
            "Exe: Only prop can call"
        );
        require(
            dotExe_[_exeID].creator != address(0),
            "Exe: Exe does not exist"
        );

        return (bytes32(0));
    }
}
