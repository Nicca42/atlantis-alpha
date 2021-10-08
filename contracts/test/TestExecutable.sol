// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./Testable.sol";

import "../interfaces/ICoord.sol";

contract TestExecutable is Testable {
    uint256 public aNumber;
    address public anAddress;
    bytes32 public aBytes;

    bytes32 immutable public IDENTIFIER;

    constructor(address _timer) Testable(_timer) {
        IDENTIFIER = keccak256("TEST_EXECUTABLE");
    }

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
        return bytes32(abi.encode(_string));
    }

    function encodeBytes(address _address, uint256 _number) external pure returns(bytes memory) {
        return abi.encode(_address, _number);
    }

    function encodeKeyAddress(bytes32 _key, address _index) external pure returns(bytes memory) {
        return abi.encode(_key, _index);
    }

    function encodeAddress(address _index) external pure returns(bytes memory) {
        return abi.encode(_index);
    }

    function getTime() external view returns(uint256) {
        return getCurrentTime();
    }

    function addSub(address _coord, bytes32 _subIdentifier, address _subImplementation) external {
        ICoord(_coord).addSubSystem(_subIdentifier, _subImplementation);
    }
}