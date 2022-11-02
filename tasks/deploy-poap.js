const { task } = require("hardhat/config")

task("deploy-poap", "upgrade poap contract from the address")
    .setAction(async (taskArgs) => {
        const contract = await ethers.getContractFactory("Poap");
        const baseURI = "https://futurex.dev/token/";
        const poapName = "FutureXPoap";
        // Start deployment, returning a promise that resolves to a contract object
        const contracted = await upgrades.deployProxy(contract, [poapName, poapName, baseURI, []], { initializer: '__POAP_init' });
        await contracted.deployed();
        console.log("Contract deployed to address:", contracted.address);
    });