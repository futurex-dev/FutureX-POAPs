// Not using ethers from hardhat
require('dotenv').config();
const ethers = require('ethers');

// Get Alchemy API Key
const API_KEY = process.env.API_KEY;

// Define an Alchemy Provider
const provider = new ethers.providers.AlchemyProvider('goerli', API_KEY)

const contract = require("../artifacts/contracts/Try.sol/GusNFT.json");

// Create a signer
const privateKey = process.env.PRIVATE_KEY
const signer = new ethers.Wallet(privateKey, provider)

// signer.estimateGas.method(parameter)
// Get contract ABI and address
const abi = contract.abi
const contractAddress = '0xfaC1a69cd6D429f081e8B45d742a339aEC7aAD4c'

// Create a contract instance
const myNftContract = new ethers.Contract(contractAddress, abi, signer)

// Get the NFT Metadata IPFS URL
const tokenUri = "https://gateway.pinata.cloud/ipfs/QmQ7Kto3iMJXitS8ALHdyZsuVQXJJ1ucw8QTUkMhXzbJXq"

// Call mintNFT function
const mintNFT = async () => {
    let nftTxn = await myNftContract.mintNFT(signer.address, tokenUri)
    await nftTxn.wait()
    console.log(`NFT Minted! Check it out at: https://goerli.etherscan.io/tx/${nftTxn.hash}`)
}

mintNFT()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });