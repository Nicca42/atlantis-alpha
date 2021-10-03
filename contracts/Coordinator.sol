// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./BaseSystem.sol";

contract Coordinator is BaseSystem {
    constructor(address _core) BaseSystem(CoreLib.COORD, _core) {}

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
    function isExecutable(bytes32 _exeID) external view returns(bool) {
        // TODO 
        return true;
    }
}