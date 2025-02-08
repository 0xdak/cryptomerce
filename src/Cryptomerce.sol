// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Cryptomerce
/// @author yuznumara
/// @notice Just an entrance for Cryptomerce project to complete buy/sell and swap transactions
contract Cryptomerce {
    /* Errors */
    error Cryptomerce__NotTheContractOwner();
    error Cryptomerce__InsufficientValueSent(uint256 sentValue, uint256 requiredValue);
    error Cryptomerce__ProductNotFound();
    error Cryptomerce__NotTheProductOwner();

    /* State Variables */
    struct Product {
        uint256 id;
        string name;
        uint256 price;
        bool isActive;
    }

    struct SwapRequest {
        uint256 offeredProductId;
        uint256 requestedProductId;
    }

    // enum SwapStatus {
    //     Requested,
    //     Confirmed
    // }

    address private immutable i_owner;
    Product[] private s_products;
    mapping(uint256 => address) public s_productIdToOwner;
    mapping(address swapOfferer => mapping(uint256 swapId => SwapRequest swapRequest)) private
        s_swapOffererToSwapRequests;
    uint256 private swapsCounter;

    /* Events */
    event SwapRequested(
        uint256 swapId, uint256 indexed offeredProductId, uint256 indexed requestedProductId, address indexed offerer
    );
    event SwapConfirmed(
        uint256 swapId, uint256 indexed offeredProductId, uint256 indexed requestedProductId, address indexed confirmer
    );

    /* Modifiers */

    modifier onlyOwner() {
        require(msg.sender == i_owner, Cryptomerce__NotTheContractOwner());
        _;
    }

    /* Functions */
    constructor() {
        i_owner = msg.sender;
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

    /// @notice Want to swap products with other user,
    /// @notice Firstly who wants to swap should call this function to notify other user,
    /// @notice If other user accepts the swap, then swap will be completed
    /// @param offeredProduct Product id that will be offered
    /// @param requestedProduct Product id that will be requested
    /// @dev This function is for single product swap
    function requestSwapForSingleProduct(uint256 offeredProduct, uint256 requestedProduct) public {
        require(s_products[offeredProduct].isActive, Cryptomerce__ProductNotFound());
        require(s_products[requestedProduct].isActive, Cryptomerce__ProductNotFound());
        // mapping(address swapOfferer => mapping(uint256 swapId => SwapRequest swapRequest)) private s_swapOffererToSwapRequests;
        s_swapOffererToSwapRequests[msg.sender][swapsCounter] = SwapRequest(offeredProduct, requestedProduct);
        emit SwapRequested(swapsCounter, offeredProduct, requestedProduct, msg.sender);
        swapsCounter++;
    }

    /// @notice Confirm the swap for single product
    /// @notice If the price difference is positive, the difference will be transferred to the product owner
    /// @notice If the price difference is negative, there will be a 3rd step to complete the swap
    function confirmSwapForSingleProduct(uint256 swapId, address offerer) public {
        uint256 priceDifference;
        SwapRequest memory swapRequest = s_swapOffererToSwapRequests[offerer][swapId];
        priceDifference =
            s_products[swapRequest.offeredProductId].price - s_products[swapRequest.requestedProductId].price;
        require(msg.sender == s_productIdToOwner[swapRequest.requestedProductId], Cryptomerce__NotTheProductOwner());
        if (priceDifference > 0) {
            payable(offerer).transfer(priceDifference);
        } else if (priceDifference < 0) {
            // you will want to get the price difference from offerer
            // @TODO
        }

        s_productIdToOwner[swapRequest.requestedProductId] = offerer;
        s_productIdToOwner[swapRequest.offeredProductId] = msg.sender;
        emit SwapConfirmed(swapId, swapRequest.offeredProductId, swapRequest.requestedProductId, msg.sender);
    }

    function confirmSwapForSingleProductWithPriceDifference() public {}

    /* View & Pure Functions */

    /// @notice get active products, it means only visible products
    function getActiveProducts() external view returns (Product[] memory) {
        Product[] memory activeProducts = new Product[](s_products.length);
        uint256 index = 0;

        for (uint256 i = 0; i < s_products.length; i++) {
            if (s_products[i].isActive) {
                activeProducts[index] = s_products[i];
                index++;
                // Keeps active products in order
            }
        }

        return activeProducts;
    }

    /// @notice Get product by index, if product is not active, it will throw an error
    function getProduct(uint256 index) external view returns (Product memory) {
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
