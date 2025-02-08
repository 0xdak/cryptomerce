// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Cryptomerce
/// @author yuznumara
/// @notice Just an entrance for Cryptomerce project to complete buy/sell and swap transactions
contract Cryptomerce {
    // Errors
    error Cryptomerce__NotTheContractOwner();
    error Cryptomerce__InsufficientValueSent(uint256 sentValue, uint256 requiredValue);
    error Cryptomerce__ProductNotFound();
    error Cryptomerce__NotTheProductOwner();

    // @TODO change struct to Event ?
    struct Product {
        uint256 id;
        string name;
        uint256 price; // ETH
        bool isActive;
    }

    address private immutable i_owner;
    Product[] private s_products;
    mapping(uint256 => address) public s_productIdToOwner;

    constructor() {
        i_owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == i_owner, Cryptomerce__NotTheContractOwner());
        _;
    }

    /// @notice Adds product to the products storage
    function addProduct(string memory name, uint256 price) public {
        s_productIdToOwner[s_products.length] = msg.sender;
        s_products.push(Product(s_products.length, name, price, true));
    }

    // buy product with product id
    function buyProduct(uint256 productId) public payable {
        Product memory product = s_products[productId];
        require(product.isActive, Cryptomerce__ProductNotFound());
        require(msg.value >= product.price, Cryptomerce__InsufficientValueSent(msg.value, product.price));
        payable(s_productIdToOwner[productId]).transfer(product.price);
        s_productIdToOwner[productId] = msg.sender;
    }

    /// @notice Disable visibility of the product by id
    function disableProduct(uint256 id) public {
        require(msg.sender == s_productIdToOwner[id], Cryptomerce__NotTheProductOwner());
        require(id < s_products.length, Cryptomerce__ProductNotFound());
        s_products[id].isActive = false;
    }

    /// @notice get active products, it means only visible products
    function getActiveProducts() external view returns (Product[] memory) {
        Product[] memory activeProducts = new Product[](s_products.length);
        uint256 index = 0;

        for (uint256 i = 0; i < s_products.length; i++) {
            if (s_products[i].isActive) {
                activeProducts[index] = s_products[i];
                index++; // Keeps active products in order
            }
        }

        return activeProducts;
    }

    /// @notice Get product by index, if product is not active, it will throw an error
    function getProduct(uint256 index) public view returns (Product memory) {
        require(s_products[index].isActive == true, Cryptomerce__ProductNotFound());
        return s_products[index];
    }

    /// @notice Get all products for only owner
    function getAllProducts() public view onlyOwner returns (Product[] memory) {
        return s_products;
    }

    /// @notice Get contract owner
    function getContractOwner() public view returns (address) {
        return i_owner;
    }
}
