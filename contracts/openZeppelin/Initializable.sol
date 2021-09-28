// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

//------------------------------------------------------------------------------
// MOSTLY TAKEN FROM OPEN ZEPPELIN.
//------------------------------------------------------------------------------
// Has been modified so that only the deployer can initialise the contract.
// This prevents malicious addresses from "stealing" the contract by
// initialising it with incorrect parameters.
//------------------------------------------------------------------------------

/**
 * @dev     This is a base contract to aid in writing upgradeable contracts, or 
 *          any kind of contract that will be deployed behind a proxy. Since a 
 *          proxied contract can't have a constructor, it's common to move 
 *          constructor logic to an external initializer function, usually 
 *          called `initialize`. It then becomes necessary to protect this 
 *          initializer function so it can only be called once. The 
 *          {initializer} modifier provided by this contract will have this 
 *          effect.
 *
 * TIP:     To avoid leaving the proxy in an uninitialized state, the 
 *          initializer function should be called as early as possible by 
 *          providing the encoded function call as the `_data` argument to 
 *          {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke 
 *          a parent initializer twice, or to ensure that all initializers are 
 *          idempotent. This is not verified automatically as constructors are 
 *          by Solidity.
 */
abstract contract Initializable {
    // Indicates that the contract has been initialized.
    bool private initialized_;

    // Indicates that the contract is in the process of being initialized.
    bool private initializing_;

    // Deployer address so that only deployer can initialise preventing 
    // malicious contract initialising.
    address private deployer_;
    // NOTE may need to remove this? Needs more thinking

    constructor() {
        deployer_ = msg.sender;
    }

    /**
     * @dev     Modifier to protect an initializer function from being invoked 
     *          twice. Has been modified so only deployer can initialise. 
     */
    modifier initializer() {
        require(
            initializing_ || !initialized_,
            "Init: Contract is initialized"
        );
        require(msg.sender == deployer_, "Init: Only deployer can init");

        bool isTopLevelCall = !initializing_;

        if (isTopLevelCall) {
            initializing_ = true;
            initialized_ = true;
        }

        _;

        if (isTopLevelCall) {
            initializing_ = false;
        }
    }
}
