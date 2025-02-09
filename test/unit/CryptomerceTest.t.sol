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
    address public USER = makeAddr("USER");
    address public USER2 = makeAddr("USER2");
    uint256 constant INITIAL_BALANCE = 1000;

    //sets owner and a non owner for tests
    function setUp() public {
        deployCryptomerce = new DeployCryptomerce();
        cryptomerce = deployCryptomerce.run();
        s_owner = cryptomerce.getContractOwner();
        nonOwner = address(0x123);

        vm.deal(USER, INITIAL_BALANCE);
        vm.deal(USER2, INITIAL_BALANCE);

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
        Cryptomerce.Product memory product = cryptomerce.getProduct(0);
        assertEq(product.id, 0);
        assertEq(product.name, "Product 1");
        assertEq(product.price, 100);
        assertEq(product.isActive, true);
    }

    //Tests 'disableProduct' as owner
    function testDisableProduct() public {
        console.log("testDisableProduct Caller: ", msg.sender);
        vm.startPrank(USER);
        cryptomerce.addProduct("Product 1", 100);
        cryptomerce.disableProduct(0);
        vm.stopPrank();
        vm.expectRevert(Cryptomerce.Cryptomerce__ProductNotFound.selector);
        Cryptomerce.Product memory product = cryptomerce.getProduct(0);
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

        cryptomerce.disableProduct(0);
        Cryptomerce.Product[] memory activeProducts = cryptomerce.getActiveProducts();
        // TODO: test array size

        assertEq(activeProducts[0].name, "Product 2");
        assertEq(activeProducts[1].name, "Product 3");
    }

    // Test: getAllProducts
    function testGetAllProducts() public {
        cryptomerce.addProduct("Product 1", 100);
        cryptomerce.addProduct("Product 2", 200);
        cryptomerce.addProduct("Product 3", 300);

        cryptomerce.disableProduct(1);
        vm.prank(s_owner);
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

    // test buy product
    // first append two products, buyProduct,
    // 1. check if the product is bought (is owner set)
    // 2. buyer's balance decreases, seller's balance increases
    function testBuyProduct() public {
        uint256 previosBalanceOfUser = address(USER).balance;
        uint256 previosBalanceOfUser2 = address(USER2).balance;
        vm.prank(USER);
        cryptomerce.addProduct("Product 1", 100);
        address previousOwner = cryptomerce.s_productIdToOwner(0);
        assertEq(previousOwner, USER);

        vm.prank(USER2);
        cryptomerce.buyProduct{value: 100}(0);
        address newOwner = cryptomerce.s_productIdToOwner(0);
        assertEq(newOwner, USER2);

        assertEq(address(USER).balance, previosBalanceOfUser + 100);
        assertEq(address(USER2).balance, previosBalanceOfUser2 - 100);
    }

    function testRequestSwapForSingleProductWithDisabledProduct() public {
        vm.prank(USER);
        cryptomerce.addProduct("Product 1", 100);
        vm.startPrank(USER2);
        cryptomerce.addProduct("Product 2", 100);
        cryptomerce.disableProduct(1);
        vm.stopPrank();

        vm.prank(USER);
        vm.expectRevert(Cryptomerce.Cryptomerce__ProductNotFound.selector);
        cryptomerce.requestSwapForSingleProduct(0, 1);
    }

    function testRequestSwapForSingleProduct() public {
        uint256 swapId;
        Cryptomerce.SwapRequest memory swapRequest;
        vm.prank(USER);
        cryptomerce.addProduct("Product 1", 100);
        vm.startPrank(USER2);
        cryptomerce.addProduct("Product 2", 100);
        vm.stopPrank();

        vm.prank(USER);
        swapId = cryptomerce.requestSwapForSingleProduct(0, 1);
        swapRequest = cryptomerce.getSwapRequestById(swapId, USER);
        assertEq(swapRequest.offeredProductId, 0);
        assertEq(swapRequest.requestedProductId, 1);

        //@TODO test emit SwapRequested
    }

    function testCompleteSwapForSingleProductIfPriceDifferentIsZero() public {
        uint256 swapId;
        Cryptomerce.SwapRequest memory swapRequest;
        vm.prank(USER);
        cryptomerce.addProduct("Product 1", 100);
        vm.startPrank(USER2);
        cryptomerce.addProduct("Product 2", 100);
        vm.stopPrank();

        vm.prank(USER);
        swapId = cryptomerce.requestSwapForSingleProduct(0, 1);
        vm.prank(USER2);
        cryptomerce.completeSwapForSingleProduct(swapId, USER); //@TODO swapId yerine 4 girince ProductOwner hatasi veriyor
        swapRequest = cryptomerce.getSwapRequestById(swapId, USER);

        assertEq(cryptomerce.s_productIdToOwner(0), USER2);
        assertEq(cryptomerce.s_productIdToOwner(1), USER);

        //@TODO test emit SwapCompleted
    }

    function testCompleteSwapForSingleProductIfPriceDifferenceIsPositive() public {
        uint256 swapId;
        Cryptomerce.SwapRequest memory swapRequest;
        uint256 previousOffererBalance = USER.balance;
        uint256 previousOwnerOfRequestedProductBalance = USER2.balance;
        vm.prank(USER);
        cryptomerce.addProduct("Product 1", 200);
        vm.prank(USER2);
        cryptomerce.addProduct("Product 2", 100);

        vm.prank(USER);
        swapId = cryptomerce.requestSwapForSingleProduct(0, 1);
        vm.prank(USER2);
        cryptomerce.completeSwapForSingleProduct{value: 100}(swapId, USER);
        swapRequest = cryptomerce.getSwapRequestById(swapId, USER);

        assertEq(cryptomerce.s_productIdToOwner(0), USER2);
        assertEq(cryptomerce.s_productIdToOwner(1), USER);
        assertEq(address(USER2).balance, previousOwnerOfRequestedProductBalance - 100);
        assertEq(address(USER).balance, previousOffererBalance + 100);

        //@TODO test emit SwapCompleted
    }

    function testCompleteSwapForSingleProductIfPriceDifferenceIsNegative() public {
        uint256 swapId;
        Cryptomerce.SwapRequest memory swapRequest;
        vm.prank(USER);
        cryptomerce.addProduct("Product 1", 100);
        vm.prank(USER2);
        cryptomerce.addProduct("Product 2", 200);

        vm.prank(USER);
        swapId = cryptomerce.requestSwapForSingleProduct(0, 1);
        vm.prank(USER2);
        cryptomerce.completeSwapForSingleProduct(swapId, USER);
        swapRequest = cryptomerce.getSwapRequestById(swapId, USER);

        // ownerships should be still same
        assertEq(cryptomerce.s_productIdToOwner(0), USER);
        assertEq(cryptomerce.s_productIdToOwner(1), USER2);
        assertEq(
            uint256(cryptomerce.getSwapRequestById(swapId, USER).status), uint256(Cryptomerce.SwapStatus.Confirmed)
        );
    }

    // price difference is negative
    function testCompleteSwapWithPayingThePriceDifference() public {
        uint256 swapId;
        uint256 previousOffererBalance = USER.balance;
        uint256 previousOwnerOfRequestedProductBalance = USER2.balance;

        Cryptomerce.SwapRequest memory swapRequest;
        vm.prank(USER);
        cryptomerce.addProduct("Product 1", 100);
        vm.prank(USER2);
        cryptomerce.addProduct("Product 2", 200);

        vm.prank(USER);
        swapId = cryptomerce.requestSwapForSingleProduct(0, 1);
        vm.prank(USER2);
        cryptomerce.completeSwapForSingleProduct(swapId, USER);
        swapRequest = cryptomerce.getSwapRequestById(swapId, USER);

        vm.prank(USER);
        cryptomerce.completeSwapWithPayingThePriceDifference{value: 100}(swapId);
        assertEq(cryptomerce.s_productIdToOwner(0), USER2);
        assertEq(cryptomerce.s_productIdToOwner(1), USER);
        assertEq(address(USER2).balance, previousOwnerOfRequestedProductBalance + 100);
        assertEq(address(USER).balance, previousOffererBalance - 100);
    }
}
