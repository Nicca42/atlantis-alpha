// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract TestExecutable {
    uint256 public aNumber;
    address public anAddress;
    bytes32 public aBytes;

    function setNumber(
        uint256 _aNumber
    )   
        external 
    {
        aNumber = _aNumber;
        anAddress = msg.sender;
    }

    function setBytes(
        bytes32 _aBytes
    )   
        external 
    {
        aBytes = _aBytes;
        anAddress = msg.sender;
    }

    function isExecutable(bytes32 _exeID) external pure returns(bool) {
        return true;
    }
}