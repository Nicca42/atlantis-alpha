// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./CoreLib.sol";
import "./interfaces/ICore.sol";
import "./openZeppelin/Initializable.sol";

abstract contract BaseSystem is Initializable {
    bytes32 immutable public IDENTIFIER;

    ICore immutable public core_;

    modifier onlyCore() {
        require(ICore(msg.sender) == core_, "System: Only core can modify");
        _;
    }

    constructor(bytes32 _key, address _core) {
        IDENTIFIER = _key;
        core_ = ICore(_core);
    }
}