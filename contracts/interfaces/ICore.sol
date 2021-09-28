// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface ICore {
    function getInstance(bytes32 _key) external view returns (address);

    function IDENTIFIER() external view returns(bytes32);
}