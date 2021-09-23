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

contract Core {
    struct Instance {
        address implementation;
        bytes4 functionSig;
    }

    mapping(bytes32 => Instance) private ecosystem_;

    // QS constructor calls loop to add all core contracts at deploy

    modifier onlyCore() {
        require(msg.sender == address(this), "Core: Only exes can modify");
        _;
    }

    constructor(address[] memory _instances) {}

    function getContract(bytes32 _key) external view returns (address, bytes4) {
        return (
            ecosystem_[_key].implementation,
            ecosystem_[_key].functionSig
        );
    }

    function addContract(
        bytes32 _key,
        address _instance,
        bytes4 _function
    ) external onlyCore {
        require(
            ecosystem_[_key].implementation == address(0),
            "Core: use update to replace"
        );
        _addContract(_key, _instance, _function);
    }

    function updateContract(
        bytes32 _key,
        address _instance,
        bytes4 _function
    ) external onlyCore {
        _addContract(_key, _instance, _function);
    }

    function execute(bytes32 _exeID) external {
        // TODO check proposal is valid for execution
        // NOTE what if we don't verify the prop passes here, but do that in the
            // coordinator. Then here all we have to do is execute. 
            // Could even call the coord to make sure that the Exe has exectuion rights,
            // then it can verify that the prop it is connected to has passed. 

        // (address coord, bytes4 sig) = this.getContract(CoreLib.COORD);
        // (
        //     bool success,
        //     bytes memory returnData
        // ) = coord.call{value:0}(
        //     abi.encodePacked(
        //         sig, 
        //         _propID
        //     )
        // );

        (address exe, ) = this.getContract(CoreLib.EXE);
        (
            address[] memory targets,
            bytes[] memory callData,
            uint256[] memory values
        ) = IExe(exe).getExe(_exeID);

        for (uint256 i = 0; i < targets.length; i++) {
            (bool success, ) = targets[i].call{
                    value: values[i]
                }(
                    callData[i]
                );
            require(success, "Core: Exe failed");
        }
    }

    function _addContract(
        bytes32 _key,
        address _instance,
        bytes4 _function
    ) internal {
        ecosystem_[_key].implementation = _instance;
        ecosystem_[_key].functionSig = _function;
    }
}