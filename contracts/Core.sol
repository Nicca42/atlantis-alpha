// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./CoreLib.sol";
import "./openZeppelin/Initializable.sol";
import "./interfaces/IExe.sol";
import "./interfaces/ICoord.sol";

/**
 * @author  Veronica | @Nicca42 - GitHub | @vonnie610 - Twitter
 * @title   Core DAO contract for an Atlantis DAO.
 * @notice  This contract is incredibly simple with very limited functionality.
 *          The "business logic" (voting, proposals, consensus etc) is done
 *          elsewhere, meaning the core contract will not need to be upgraded to
 *          increase functionality.
 */
contract Core is Initializable {

    //--------------------------------------------------------------------------
    // STATE
    //--------------------------------------------------------------------------

    bytes32 public constant IDENTIFIER = bytes32(keccak256("CORE"));

    mapping(bytes32 => address) private ecosystem_;

    //--------------------------------------------------------------------------
    // EVENTS
    //--------------------------------------------------------------------------

    event ImplementationChanged(
        bytes32 key,
        address oldImplementation,
        address newImplementation
    );

    //--------------------------------------------------------------------------
    // MODIFIERS
    //--------------------------------------------------------------------------

    modifier onlyCore() {
        require(msg.sender == address(this), "Core: Only exes can modify");
        _;
    }

    //--------------------------------------------------------------------------
    // CONSTRUCTOR
    //--------------------------------------------------------------------------

    function initialise(
        address _coord,
        address _executables,
        address _props,
        address _voteWeight,
        address _votingBooth
    ) external initializer {
        _addContract(CoreLib.COORD, _coord);
        _addContract(CoreLib.EXE, _executables);
        _addContract(CoreLib.PROPS, _props);
        _addContract(CoreLib.VOTE_WEIGHT, _voteWeight);
        _addContract(CoreLib.VOTE_BOOTH, _votingBooth);
    }

    //--------------------------------------------------------------------------
    // VIEW & PURE FUNCTIONS
    //--------------------------------------------------------------------------

    function getInstance(bytes32 _key) external view returns (address) {
        return ecosystem_[_key];
    }

    //--------------------------------------------------------------------------
    // PUBLIC & EXTERNAL FUNCTIONS
    //--------------------------------------------------------------------------

    /**
     * @param   _exeID ID of executable.
     * @notice  Executes the passed executable. The executable needs to be
     *          marked as executable on the coordinator. If the exe ID is not
     *          approved for execution on the coordinator the transaction will
     *          fail.
     */
    function execute(bytes32 _exeID) external {
        // NOTE does this need re-entrancy guard?
        ICoord coord = ICoord(this.getInstance(CoreLib.COORD));

        coord.setExecute(_exeID);

        IExe exe = IExe(this.getInstance(CoreLib.EXE));
        // Gets the data for the executable
        (
            address[] memory targets,
            bytes[] memory callData,
            uint256[] memory values
        ) = exe.getExe(_exeID);

        // Executes each step of the executable
        for (uint256 i = 0; i < targets.length; i++) {
            (bool success, ) = targets[i].call{value: values[i]}(callData[i]);
            require(success, "Core: Exe failed");
        }
    }

    //--------------------------------------------------------------------------
    // ONLY CORE
    //
    // Below functions can only be called by this contract. These functions can
    // only be executed by successfully running an executable through the
    // `execute` function.

    function addContract(bytes32 _key, address _instance) external onlyCore {
        require(ecosystem_[_key] == address(0), "Core: Use update to replace");
        require(_instance != address(0), "Core: Cannot delete on add");

        _addContract(_key, _instance);
    }

    function updateContract(bytes32 _key, address _instance) external onlyCore {
        require(ecosystem_[_key] != address(0), "Core: Cannot add on update");
        require(_instance != address(0), "Core: Cannot delete on update");

        _addContract(_key, _instance);
    }

    function deleteContract(bytes32 _key) external onlyCore {
        require(ecosystem_[_key] != address(0), "Core: already deleted");

        _addContract(_key, address(0));
    }

    //--------------------------------------------------------------------------
    // PRIVATE & INTERNAL FUNCTIONS
    //--------------------------------------------------------------------------

    function _addContract(bytes32 _key, address _instance) internal {
        emit ImplementationChanged(_key, ecosystem_[_key], _instance);

        ecosystem_[_key] = _instance;
    }
}
