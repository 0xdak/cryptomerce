// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Cryptomerce} from "src/Cryptomerce.sol";
import {DeployCryptomerce} from "script/DeployCryptomerce.sol";
import {Test} from "forge-std/Test.sol";

contract CryptomerceTest is Test {
    Cryptomerce cryptomerce;
    DeployCryptomerce deployCryptomerce;

    function setUp() public {
        deployCryptomerce = new DeployCryptomerce();
        cryptomerce = deployCryptomerce.run();
    }

    // test product adding is working correctly
    function testAddProduct() public {
        cryptomerce.addProduct("Product 1", 100);
        (uint256 id, string memory name, uint256 price) = cryptomerce
            .s_products(0);
        assertEq(id, 0);
        assertEq(name, "Product 1");
        assertEq(price, 100);
    }
}
