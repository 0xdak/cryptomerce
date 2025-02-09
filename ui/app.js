const contractAddress = '0x5FbDB2315678afecb367f032d93F642f64180aa3';
const contractABI = [
    {
        "type": "constructor",
        "inputs": [],
        "stateMutability": "nonpayable"
      },
      {
        "type": "function",
        "name": "addProduct",
        "inputs": [
          {
            "name": "name",
            "type": "string",
            "internalType": "string"
          },
          {
            "name": "price",
            "type": "uint256",
            "internalType": "uint256"
          }
        ],
        "outputs": [],
        "stateMutability": "nonpayable"
      },
      {
        "type": "function",
        "name": "buyProduct",
        "inputs": [
          {
            "name": "productId",
            "type": "uint256",
            "internalType": "uint256"
          }
        ],
        "outputs": [],
        "stateMutability": "payable"
      },
      {
        "type": "function",
        "name": "disableProduct",
        "inputs": [
          {
            "name": "id",
            "type": "uint256",
            "internalType": "uint256"
          }
        ],
        "outputs": [],
        "stateMutability": "nonpayable"
      },
      {
        "type": "function",
        "name": "getActiveProducts",
        "inputs": [],
        "outputs": [
          {
            "name": "",
            "type": "tuple[]",
            "internalType": "struct Cryptomerce.Product[]",
            "components": [
              {
                "name": "id",
                "type": "uint256",
                "internalType": "uint256"
              },
              {
                "name": "name",
                "type": "string",
                "internalType": "string"
              },
              {
                "name": "price",
                "type": "uint256",
                "internalType": "uint256"
              },
              {
                "name": "isActive",
                "type": "bool",
                "internalType": "bool"
              }
            ]
          }
        ],
        "stateMutability": "view"
      },
      {
        "type": "function",
        "name": "getAllProducts",
        "inputs": [],
        "outputs": [
          {
            "name": "",
            "type": "tuple[]",
            "internalType": "struct Cryptomerce.Product[]",
            "components": [
              {
                "name": "id",
                "type": "uint256",
                "internalType": "uint256"
              },
              {
                "name": "name",
                "type": "string",
                "internalType": "string"
              },
              {
                "name": "price",
                "type": "uint256",
                "internalType": "uint256"
              },
              {
                "name": "isActive",
                "type": "bool",
                "internalType": "bool"
              }
            ]
          }
        ],
        "stateMutability": "view"
      },
      {
        "type": "function",
        "name": "getContractOwner",
        "inputs": [],
        "outputs": [
          {
            "name": "",
            "type": "address",
            "internalType": "address"
          }
        ],
        "stateMutability": "view"
      },
      {
        "type": "function",
        "name": "getProduct",
        "inputs": [
          {
            "name": "index",
            "type": "uint256",
            "internalType": "uint256"
          }
        ],
        "outputs": [
          {
            "name": "",
            "type": "tuple",
            "internalType": "struct Cryptomerce.Product",
            "components": [
              {
                "name": "id",
                "type": "uint256",
                "internalType": "uint256"
              },
              {
                "name": "name",
                "type": "string",
                "internalType": "string"
              },
              {
                "name": "price",
                "type": "uint256",
                "internalType": "uint256"
              },
              {
                "name": "isActive",
                "type": "bool",
                "internalType": "bool"
              }
            ]
          }
        ],
        "stateMutability": "view"
      },
      {
        "type": "function",
        "name": "s_productIdToOwner",
        "inputs": [
          {
            "name": "",
            "type": "uint256",
            "internalType": "uint256"
          }
        ],
        "outputs": [
          {
            "name": "",
            "type": "address",
            "internalType": "address"
          }
        ],
        "stateMutability": "view"
      },
      {
        "type": "error",
        "name": "Cryptomerce__InsufficientValueSent",
        "inputs": [
          {
            "name": "sentValue",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "requiredValue",
            "type": "uint256",
            "internalType": "uint256"
          }
        ]
      },
      {
        "type": "error",
        "name": "Cryptomerce__NotTheContractOwner",
        "inputs": []
      },
      {
        "type": "error",
        "name": "Cryptomerce__NotTheProductOwner",
        "inputs": []
      },
      {
        "type": "error",
        "name": "Cryptomerce__ProductNotFound",
        "inputs": []
      }
];

async function loadActiveProducts() {
    if (window.ethereum) {
        const web3 = new Web3(window.ethereum);
        await window.ethereum.enable();

        const contract = new web3.eth.Contract(contractABI, contractAddress);

        try {
            const activeProducts = await contract.methods.getActiveProducts().call();
            displayProducts(activeProducts);
        } catch (error) {
            console.error('Error fetching active products:', error);
        }
    } else {
        console.error('Ethereum provider not found. Install MetaMask.');
    }
}

function displayProducts(products) {
    const productList = document.getElementById('productList');
    productList.innerHTML = '';

    products.forEach(product => {
        if (product.isActive) {
            const listItem = document.createElement('li');
            listItem.textContent = `ID: ${product.id}, Name: ${product.name}, Price: ${product.price} ETH`;
            productList.appendChild(listItem);
        }
    });
}


document.getElementById('addProductForm').addEventListener('submit', async (event) => {
    event.preventDefault();

    const productName = document.getElementById('productName').value;
    const productPrice = document.getElementById('productPrice').value;

    if (window.ethereum) {
        const web3 = new Web3(window.ethereum);
        await window.ethereum.enable();

        const contract = new web3.eth.Contract(contractABI, contractAddress);

        try {
            const accounts = await web3.eth.getAccounts();
            await contract.methods.addProduct(productName, web3.utils.toWei(productPrice, 'ether')).send({ from: accounts[0] });
            alert('Product added successfully!');
            loadActiveProducts(); // Refresh the product list
        } catch (error) {
            console.error('Error adding product:', error);
        }
    } else {
        console.error('Ethereum provider not found. Install MetaMask.');
    }
});

async function requestSwapForSingleProduct(requesterProductId, requestedProductId) {
  if (window.ethereum) {
      const web3 = new Web3(window.ethereum);
      await window.ethereum.enable();

      const contract = new web3.eth.Contract(contractABI, contractAddress);

      try {
          const accounts = await web3.eth.getAccounts();
          await contract.methods.requestSwapForSingleProduct(requesterProductId, requestedProductId).send({ from: accounts[0] });
          alert('Swap request sent successfully!');
      } catch (error) {
          console.error('Error requesting swap:', error);
      }
  } else {
      console.error('Ethereum provider not found. Install MetaMask.');
  }
}



