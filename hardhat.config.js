require("@nomicfoundation/hardhat-toolbox");
require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-web3");
require("hardhat-gas-reporter");
require("solidity-coverage");
require('@openzeppelin/hardhat-upgrades');




/** @type import('hardhat/config').HardhatUserConfig */
require('dotenv').config();
require("@nomiclabs/hardhat-ethers");
require("./tasks/upgrade-poap")
require("./tasks/deploy-poap")
module.exports = {
  solidity: "0.8.7",
  gasReporter: {
    enabled: process.env.REPORT_GAS
  },
  allowUnlimitedContractSize: true,
  networks: {
    hardhat: {},
  },
};

const { Goerli_API_URL, Goerli_PRIVATE_KEY } = process.env;
if (Goerli_API_URL) {
  module.exports['networks']['goerli'] = {
    url: Goerli_API_URL,
    accounts: [`0x${Goerli_PRIVATE_KEY}`]
  };
}