async function main() {
  // Grab the contract factory 
  const MyNFT = await ethers.getContractFactory("GusNFT");

  // Start deployment, returning a promise that resolves to a contract object
  const myNFT = await MyNFT.deploy(); // Instance of the contract 
  await myNFT.deployed();
  console.log("Contract deployed to address:", myNFT.address);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });