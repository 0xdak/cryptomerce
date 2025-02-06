// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Cryptomerce} from "src/Cryptomerce.sol";
import {DeployCryptomerce} from "script/DeployCryptomerce.sol";
import {Test, console} from "forge-std/Test.sol";

contract CryptomerceTest is Test {
    Cryptomerce cryptomerce;
    DeployCryptomerce deployCryptomerce;
    address public s_owner;
    address nonOwner;

    //sets owner and a non owner for tests
    function setUp() public {
        deployCryptomerce = new DeployCryptomerce();
        cryptomerce = deployCryptomerce.run();
        s_owner = cryptomerce.getContractOwner();
        nonOwner = address(0x123);

        console.log("DeployCryptomerce address: ", address(deployCryptomerce));
        console.log("Cryptomerce address: ", address(cryptomerce));
        console.log("CryptomerceTest address: ", address(this));
        console.log("Msg Sender: ", msg.sender);
        console.log("Cryptomerce Owner: ", s_owner);
    }

    function testGetContractOwner() public view {
        address actualOwner = cryptomerce.getContractOwner();
        assertEq(actualOwner, s_owner);
    }

    // test product adding is working correctly
    function testAddProduct() public {
        cryptomerce.addProduct("Product 1", 100);
        (
            uint256 id,
            string memory name,
            uint256 price,
            bool isActive
        ) = cryptomerce.s_products(0);
        assertEq(id, 0);
        assertEq(name, "Product 1");
        assertEq(price, 100);
        assertEq(isActive, true);
    }

    //Tests 'disableProduct' as owner
    function testDisableProduct() public {
        console.log("testDisableProduct Caller: ", msg.sender);
        cryptomerce.addProduct("Product 1", 100);
        vm.prank(s_owner);
        cryptomerce.disableProduct(0);
        (
            uint256 id,
            string memory name,
            uint256 price,
            bool isActive
        ) = cryptomerce.s_products(0);
        assertEq(id, 0);
        assertEq(name, "Product 1");
        assertEq(price, 100);
        assertEq(isActive, false);
    }

    //Tests 'onlyOwner' modifier and expects 'revert' error
    function testNonOwnerDisableProduct() public {
        vm.prank(nonOwner);
        vm.expectRevert();
        cryptomerce.disableProduct(0);
    }

    // Test: getActiveProducts
    function testGetActiveProducts() public {
        cryptomerce.addProduct("Product 1", 100);
        cryptomerce.addProduct("Product 2", 200);
        cryptomerce.addProduct("Product 3", 300);

        vm.prank(s_owner);
        cryptomerce.disableProduct(0);
        Cryptomerce.Product[] memory activeProducts = cryptomerce
            .getActiveProducts();
        // TODO: test array size

        assertEq(activeProducts[0].name, "Product 2");
        assertEq(activeProducts[1].name, "Product 3");
    }

    // Test: getAllProducts
    function testGetAllProducts() public {
        cryptomerce.addProduct("Product 1", 100);
        cryptomerce.addProduct("Product 2", 200);
        cryptomerce.addProduct("Product 3", 300);

        vm.startPrank(s_owner);
        cryptomerce.disableProduct(1);
        Cryptomerce.Product[] memory allProducts = cryptomerce.getAllProducts();

        assertEq(allProducts.length, 3);

        assertEq(allProducts[0].name, "Product 1");
        assertEq(allProducts[1].name, "Product 2");
        assertEq(allProducts[2].name, "Product 3");
    }

    //Tests 'onlyOwner' modifier and expects 'revert' error
    function testNonOwnerGetAllProducts() public {
        vm.prank(nonOwner);
        vm.expectRevert();
        cryptomerce.getAllProducts();
    }
}
