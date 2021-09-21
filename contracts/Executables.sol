// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract Executables {

    function getExe(bytes32 _exeID) external view returns(
        address[] memory targets,
        bytes[] memory callData,
        uint256[] memory values
    ) {
        // QS return data
    }

    function getExeInfo(bytes32 _exeID) external view returns(
        address[] memory targets,
        bytes[] memory callData,
        uint256[] memory values,
        string memory description, 
        address creator
    ) {
        // QS return data
    }

    function createExe(
        address[] calldata _targets,
        string[] calldata _functionSignatures,
        bytes[] calldata _encodedParameters,
        uint256[] calldata _values,
        string calldata _description
    ) external returns(bytes32 exeID) {
        // TODO encode function sigs and econded parameters into calldata

        // QS store exe

        return bytes32(0);
    }
}