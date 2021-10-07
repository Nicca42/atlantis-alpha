// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./Testable.sol";

contract TestExecutable is Testable {
    uint256 public aNumber;
    address public anAddress;
    bytes32 public aBytes;

    constructor(address _timer) Testable(_timer) {}

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

    function encodeBool(bool _input) external pure returns(bytes memory) {
        return abi.encode(_input);
    }

    function encodeBytes32(string calldata _string) external pure returns(bytes32) {
        return bytes32(abi.encodePacked(_string));
    }

    function encodeBytes4(string calldata _string) external pure returns(bytes32) {
        return bytes4(abi.encodePacked(_string));
    }

    function encodeBytes(address _address, uint256 _number) external pure returns(bytes memory) {
        return abi.encodePacked(_address, _number);
    }

    function getTime() external view returns(uint256) {
        return getCurrentTime();
    }
}