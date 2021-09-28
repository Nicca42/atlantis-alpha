// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./CoreLib.sol";

interface IExe {
    function getExe(bytes32 _exeID) external view returns(
        address[] memory targets,
        bytes[] memory callData,
        uint256[] memory values
    );
}

interface ICoord {
    /**
     * @param   _propID ID of the proposal to execute. 
     * @notice  This function will check that the specified proposal has reached
     *          quorum, and that it has passed. If the proposal has not reached
     *          quorum or has not passed this will return false. 
     * @dev     This function will update the state for the proposal if it has
     *          not already been marked as executable. 
     */
    function execute(uint256 _propID) external returns(bool);

    // QS update to use just this. 
    function isExecutable(bytes32 _exeID) external view returns(bool);
}

contract Core {
    bytes32 public constant IDENTIFIER = bytes32(keccak256("CORE"));

    struct Instance {
        address implementation;
        bytes4 functionSig;
    }

    mapping(bytes32 => Instance) private ecosystem_;

    modifier onlyCore() {
        require(msg.sender == address(this), "Core: Only exes can modify");
        _;
    }

    constructor(
        address _coord,
        address _exes,
        address _props,
        address _voteWeight,
        address _votingBooth,
        address _voteStorage
    ) {
        _addContract(CoreLib.COORD, _coord);
        _addContract(CoreLib.EXE, _exes);
        _addContract(CoreLib.PROPS, _props);
        _addContract(CoreLib.VOTE_WEIGHT, _voteWeight);
        _addContract(CoreLib.VOTE_BOOTH, _votingBooth);
        _addContract(CoreLib.VOTE_STORAGE, _voteStorage);
    }


    //--------------------------------------------------------------------------
    // VIEW & PURE FUNCTIONS
    //--------------------------------------------------------------------------

    function getInstance(bytes32 _key) external view returns(address) {
        return ecosystem_[_key].implementation;
    }

    function getContract(bytes32 _key) external view returns (address, bytes4) {
        return (
            ecosystem_[_key].implementation,
            ecosystem_[_key].functionSig
        );
    }

    //--------------------------------------------------------------------------
    // PUBLIC & EXTERNAL FUNCTIONS
    //--------------------------------------------------------------------------

    function execute(bytes32 _exeID) external {
        ICoord coord = ICoord(this.getInstance(CoreLib.COORD));

        require(
            coord.isExecutable(_exeID),
            "Core: Exe is not executable"
        );

        IExe exe = IExe(this.getInstance(CoreLib.EXE));

        // Gets the data for the executable
        (
            address[] memory targets,
            bytes[] memory callData,
            uint256[] memory values
        ) = exe.getExe(_exeID);
        // Executes each step of the executable
        for (uint256 i = 0; i < targets.length; i++) {
            (bool success, ) = targets[i].call{
                    value: values[i]
                }(
                    callData[i]
                );
            require(success, "Core: Exe failed");
        }
    }

    //--------------------------------------------------------------------------
    // ONLY CORE 
    // 
    // Below functions can only be called by this contract. These functions can
    // only be executed by successfully running an executable through the 
    // `execute` function. 

    function addContract(
        bytes32 _key,
        address _instance,
        bytes4 _function
    ) external onlyCore {
        require(
            ecosystem_[_key].implementation == address(0),
            "Core: Use update to replace"
        );
        require(_instance != address(0), "Core: Cannot delete on add");

        _addContract(_key, _instance);
    }

    function updateContract(
        bytes32 _key,
        address _instance,
        bytes4 _function
    ) external onlyCore {
        require(
            ecosystem_[_key].implementation != address(0),
            "Core: Cannot add on update"
        );
        require(_instance != address(0), "Core: Cannot delete on update");

        _addContract(_key, _instance);
    }

    function deleteContract(
        bytes32 _key
    ) external onlyCore {
        require(
            ecosystem_[_key].implementation != address(0),
            "Core: already deleted"
        );

        _addContract(_key, address(0));
    }

    //--------------------------------------------------------------------------
    // PRIVATE & INTERNAL FUNCTIONS
    //--------------------------------------------------------------------------

    function _addContract(
        bytes32 _key,
        address _instance
    ) internal {
        ecosystem_[_key].implementation = _instance;
    }
}