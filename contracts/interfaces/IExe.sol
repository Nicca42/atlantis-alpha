// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IExe {
    /**
     * @param   _exeID ID of the executable to get the data of.
     * @return  targets The array of target addresses.
     * @return  callData The array of calldata to execute at each address.
     * @return  values The array of values (in native tokens) to pass through
     *          with each call. Note that these values are outside of any gas
     *          requirements and costs.
     */
    function getExe(bytes32 _exeID)
        external
        view
        returns (
            address[] memory targets,
            bytes[] memory callData,
            uint256[] memory values
        );

    function createPropExe(
        uint256 _propID,
        bytes32 _exeID,
        string memory _description
    ) external returns (bytes32 propExeID);
}