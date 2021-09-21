// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract Core {
    // QS save keys to instances

    // QS constructor calls loop to add all core contracts at deploy

    function getContract(bytes32 _key) external view returns(address) {
        
        // QS should return the instance of the contract
        
        return address(0);
    }

    function addContract(bytes32 _key, address _instance) external {
        // QS save the contract

        // TODO modifer so that only the core address can call this
    }

    function execute(uint256 _propID) external {
        // TODO check proposal is valid for execution
        // (
        //     bool valid, 
        //     bytes32 exeID
        // ) = this.getContract(coreLib.coord).isPropExecutable(_propID);

        // TODO execute exe
    }

    // QS make internal function to add contracts
}