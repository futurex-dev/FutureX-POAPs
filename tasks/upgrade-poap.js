const { task } = require("hardhat/config")

task("upgrade-poap", "upgrade poap contract from the address")
    .addPositionalParam("address", "The proxy contract address")
    .setAction(async (taskArgs) => {
        console.log("Proxy contract address: ", taskArgs['address']);
        const contract = await ethers.getContractFactory("Poap");
        // Start deployment, returning a promise that resolves to a contract object
        const contracted = await upgrades.upgradeProxy(taskArgs['address'], contract);
        await contracted.deployed();
        console.log("Contract deployed to address:", contracted.address);
    });