async function main() {
  // Grab the contract factory 
  const contract = await ethers.getContractFactory("Poap");

  // Start deployment, returning a promise that resolves to a contract object
  const contracted = await contract.deploy(); // Instance of the contract 
  await contracted.deployed();
  console.log("Contract deployed to address:", contracted.address);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });