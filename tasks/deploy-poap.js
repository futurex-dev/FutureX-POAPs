const { task } = require("hardhat/config")

task("deploy-poap", "upgrade poap contract from the address")
    .setAction(async (taskArgs) => {
        const contract = await ethers.getContractFactory("Poap");
        const baseURI = "https://futurex.dev/token/";
        const poapName = "FutureXPoap";
        // Start deployment, returning a promise that resolves to a contract object
        const gas_price = await ethers.provider.getGasPrice();
        const estimatedGas = await ethers.provider.estimateGas(contract.getDeployTransaction().data)
        console.log(`Estimate deploy gas fee: ${estimatedGas * gas_price / 1e18} eth with Gas ${estimatedGas} and price ${gas_price / 1e18}`);

        const contracted = await upgrades.deployProxy(contract, [poapName, poapName, baseURI, []], { initializer: '__POAP_init' });
        await contracted.deployed();
        const receipt = await contracted.deployTransaction.wait();
        console.log("Contract deployed to address:", contracted.address);
        console.log(`Costed gas fee: ${receipt.effectiveGasPrice * receipt.gasUsed / 1e18} eth with Gas ${receipt.gasUsed} and price ${receipt.effectiveGasPrice}`)
    });