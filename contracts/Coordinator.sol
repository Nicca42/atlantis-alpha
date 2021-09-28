// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./interfaces/ICore.sol";
import "./CoreLib.sol";
// QS make common contract with interface and library
import "./openZeppelin/Initializable.sol";

contract Coordinator is Initializable {
    bytes32 public constant IDENTIFIER = bytes32(keccak256("COORDINATOR"));

    ICore immutable public core;

    constructor(address _core) {
        core = ICore(_core);
    }

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