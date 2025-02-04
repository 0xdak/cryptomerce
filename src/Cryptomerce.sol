// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Cryptomerce
/// @author yuznumara
/// @notice Just a entrance for Cryptomerce project to complete buy/sell and swap transactions
contract Cryptomerce {
    // Errors
    error Cryptomerce__NotTheContractOwner();

    struct Product {
        uint256 id;
        string name;
        uint256 price; // ETH
    }

    address private immutable i_owner;
    Product[] public s_products;

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
}
