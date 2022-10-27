async function main() {
    // Grab the contract factory 
    const [owner] = await ethers.getSigners();
    const provider = ethers.provider;
    const gas_price = await provider.getGasPrice();
    console.log("Deploying contracts with the account:", owner.address);
    console.log("Current Gas price:", gas_price);

    const NFT = await ethers.getContractFactory("GusNFT");

    // Estimating
    const estimatedGas = await ethers.provider.estimateGas(NFT.getDeployTransaction().data)
    // console.log(NFT.getDeployTransaction().data);
    console.log(`Deploy fee ${estimatedGas * gas_price / 1e9}`);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });