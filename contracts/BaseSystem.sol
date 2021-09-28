// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./CoreLib.sol";
import "./interfaces/ICore.sol";

abstract contract BaseSystem {
    bytes32 immutable public IDENTIFIER;

    ICore immutable public core_;

    constructor(bytes32 _key, address _core) {
        IDENTIFIER = _key;
        core_ = ICore(_core);
    }
}