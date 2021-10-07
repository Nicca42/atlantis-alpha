// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface ICoord {
    function getSubSystem(address _system, bytes32 _subIdentifier)
        external
        view
        returns (address);

    function isVotable(uint256 _propID) external view returns (bool);

    function addSubSystem(bytes32 _subIdentifier, address _subImplementation)
        external;

    function voting(uint256 _propID) external returns(bool);

    /**
     * @param   _exeID ID of the executable to check.
     * @notice  This function will check that the specified proposal has reached
     *          quorum, and that it has passed. If the proposal has not reached
     *          quorum or has not passed this will return false.
     * @dev     The reason we use Exe IDs here and not Prop IDs is that
     *          executables may be valid for execution outside of a proposal
     *          (e.g an approved recurring payment). If the exe is tied to a
     *          proposal the coordinator will be able to look up and verify it's
     *          executable status.
     */
    function isExecutable(bytes32 _exeID) external view returns (bool);

    function setExecute(bytes32 _exeID) external;
}