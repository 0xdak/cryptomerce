// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";

/// @title Cryptomerce
/// @author yuznumara
/// @notice Just an entrance for Cryptomerce project to complete buy/sell and swap transactions
contract Cryptomerce {
    /* Errors */
    error Cryptomerce__NotTheContractOwner();
    error Cryptomerce__InsufficientValueSent(uint256 sentValue, uint256 requiredValue);
    error Cryptomerce__ProductNotFound();
    error Cryptomerce__NotTheProductOwner();
    error Cryptomerce__TransferFailed();
    error Cryptomerce__NotEnoughValueSent(uint256 sentValue, uint256 requiredValue);
    error Cryptomerce__SwapRequestIsNotConfirmedYet();
    error Cryptomerce__SwapRequestIsConfirmedOrCompletedAlready();

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
        SwapStatus status;
    }

    enum SwapStatus {
        Requested,
        Confirmed,
        Completed
    }

    address private immutable i_owner;
    Product[] private s_products;
    mapping(uint256 => address) public s_productIdToOwner;
    mapping(address swapOfferer => mapping(uint256 swapId => SwapRequest swapRequest)) private
        s_swapOffererToSwapRequests;
    uint256 private swapsCounter = 1;

    /* Events */
    event SwapRequested(
        uint256 swapId, uint256 indexed offeredProductId, uint256 indexed requestedProductId, address indexed offerer
    );
    event SwapCompleted(
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
        payable(msg.sender).transfer(msg.value - product.price);
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
    function requestSwapForSingleProduct(uint256 offeredProduct, uint256 requestedProduct)
        public
        returns (uint256 swapId)
    {
        swapId = swapsCounter;
        require(s_productIdToOwner[offeredProduct] == msg.sender, Cryptomerce__NotTheProductOwner());
        require(requestedProduct != offeredProduct);
        require(s_products[offeredProduct].isActive, Cryptomerce__ProductNotFound());
        require(s_products[requestedProduct].isActive, Cryptomerce__ProductNotFound());
        // mapping(address swapOfferer => mapping(uint256 swapId => SwapRequest swapRequest)) private s_swapOffererToSwapRequests;
        s_swapOffererToSwapRequests[msg.sender][swapId] =
            SwapRequest(offeredProduct, requestedProduct, SwapStatus.Requested);
        emit SwapRequested(swapId, offeredProduct, requestedProduct, msg.sender);
        swapsCounter++;
        return swapId;
    }

    /// @notice Confirm the swap for single product
    /// @notice If the price difference is positive, the difference will be transferred to the product owner
    /// @notice If the price difference is negative, there will be a 3rd step to complete the swap
    // Requested -> Confirmed by owner of the requeested product
    function completeSwapForSingleProduct(uint256 swapId, address offerer) public payable {
        SwapRequest memory swapRequest = s_swapOffererToSwapRequests[offerer][swapId];
        require(swapRequest.status == SwapStatus.Requested, Cryptomerce__SwapRequestIsConfirmedOrCompletedAlready());
        require(msg.sender == s_productIdToOwner[swapRequest.requestedProductId], Cryptomerce__NotTheProductOwner());
        if (s_products[swapRequest.offeredProductId].price > s_products[swapRequest.requestedProductId].price) {
            uint256 priceDifference =
                s_products[swapRequest.offeredProductId].price - s_products[swapRequest.requestedProductId].price;
            require(msg.value >= priceDifference, Cryptomerce__NotEnoughValueSent(msg.value, uint256(priceDifference)));
            payable(offerer).transfer(priceDifference);
            payable(msg.sender).transfer(msg.value - priceDifference);
        } else if (s_products[swapRequest.offeredProductId].price < s_products[swapRequest.requestedProductId].price) {
            // you will want to get the price difference from offerer, so swap isn't completed yet
            s_swapOffererToSwapRequests[offerer][swapId].status = SwapStatus.Confirmed;
            return;
        }

        s_productIdToOwner[swapRequest.requestedProductId] = offerer;
        s_productIdToOwner[swapRequest.offeredProductId] = msg.sender;

        emit SwapCompleted(swapId, swapRequest.offeredProductId, swapRequest.requestedProductId, msg.sender);
        // Delete the swap request after confirmation
        delete s_swapOffererToSwapRequests[offerer][swapId];
    }

    /// @notice Completes the swap by paying the price difference
    /// @dev This function should be called by the offerer to complete the swap when there is a positive price difference
    /// @dev Confirmed -> Complete by Offerer
    /// @param swapId The ID of the swap request
    function completeSwapWithPayingThePriceDifference(uint256 swapId) public payable {
        SwapRequest memory swapRequest = s_swapOffererToSwapRequests[msg.sender][swapId];
        address ownerOfRequestedProduct = s_productIdToOwner[swapRequest.requestedProductId];
        require(
            s_products[swapRequest.requestedProductId].price > s_products[swapRequest.offeredProductId].price,
            "Requested product's price must be greater than offered product's price"
        );
        uint256 priceDifference =
            s_products[swapRequest.requestedProductId].price - s_products[swapRequest.offeredProductId].price;
        require(swapRequest.status == SwapStatus.Confirmed, Cryptomerce__SwapRequestIsNotConfirmedYet());
        require(msg.sender == s_productIdToOwner[swapRequest.offeredProductId], Cryptomerce__NotTheProductOwner());
        require(msg.value >= priceDifference, Cryptomerce__NotEnoughValueSent(msg.value, priceDifference));
        (bool success,) = payable(ownerOfRequestedProduct).call{value: priceDifference}("");
        require(success, Cryptomerce__TransferFailed());
        payable(msg.sender).transfer(msg.value - priceDifference);
        s_productIdToOwner[swapRequest.requestedProductId] = msg.sender;
        s_productIdToOwner[swapRequest.offeredProductId] = ownerOfRequestedProduct;
        emit SwapCompleted(swapId, swapRequest.offeredProductId, swapRequest.requestedProductId, msg.sender);
        delete s_swapOffererToSwapRequests[msg.sender][swapId];
    }

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

    /// @notice Get swap request by id
    function getSwapRequestById(uint256 swapId, address offerer) external view returns (SwapRequest memory) {
        return s_swapOffererToSwapRequests[offerer][swapId];
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
