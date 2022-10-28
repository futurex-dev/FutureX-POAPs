require("@nomicfoundation/hardhat-toolbox");
require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-web3");
require("hardhat-gas-reporter");
require("solidity-coverage");
require('@openzeppelin/hardhat-upgrades');




/** @type import('hardhat/config').HardhatUserConfig */
require('dotenv').config();
require("@nomiclabs/hardhat-ethers");
// const { API_URL, PRIVATE_KEY } = process.env;
module.exports = {
  solidity: "0.8.7",
  gasReporter: {
    enabled: process.env.REPORT_GAS
  },
  // defaultNetwork: "goerli",
  allowUnlimitedContractSize: true,
  networks: {
    hardhat: {},
    // goerli: {
    //   url: API_URL,
    //   accounts: [`0x${PRIVATE_KEY}`]
    // }
  },
};
