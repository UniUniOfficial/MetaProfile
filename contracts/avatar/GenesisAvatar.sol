// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../element/Component.sol";


contract GenesisAvatar is Component {
    constructor(address profileAddress, uint256 max_supply) 
        Component("Genesis Avatar", "GA", profileAddress, max_supply) {
    }
}