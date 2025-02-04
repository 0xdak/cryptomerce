// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Cryptomerce
/// @author yuznumara
/// @notice Just an entrance for Cryptomerce project to complete buy/sell and swap transactions
contract Cryptomerce {
    // Errors
    error Cryptomerce__NotTheContractOwner();
    error Cryptomerce__InsufficientValueSent(
        uint256 sentValue,
        uint256 requiredValue
    );

    // @TODO change struct to Event ?
    struct Product {
        uint256 id;
        string name;
        uint256 price; // ETH
    }

    address private immutable i_owner;
    Product[] public s_products;
    mapping(uint256 => address) public s_productIdToOwner;

    constructor() {
        i_owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == i_owner, Cryptomerce__NotTheContractOwner());
        _;
    }

    function addProduct(string memory name, uint256 price) public {
        s_products.push(Product(s_products.length, name, price));
    }

    function buyProduct(uint256 productId) public payable {
        Product memory product = s_products[productId];
        require(
            msg.value >= product.price,
            Cryptomerce__InsufficientValueSent(msg.value, product.price)
        );
        payable(s_productIdToOwner[productId]).transfer(msg.value);
        s_productIdToOwner[productId] = msg.sender;
    }
}
