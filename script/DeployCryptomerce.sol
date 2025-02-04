// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Cryptomerce} from "src/Cryptomerce.sol";
import {Script} from "forge-std/Script.sol";

contract DeployCryptomerce is Script {
    function run() external returns (Cryptomerce) {
        vm.startBroadcast();
        Cryptomerce cryptomerce = new Cryptomerce();
        vm.stopBroadcast();
        return cryptomerce;
    }
}
