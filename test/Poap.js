const { expect } = require("chai");
const { ethers, upgrades } = require("hardhat");


describe("Poap main test", function () {
  it("Should deploy POAPs", async function () {
    const [owner] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", owner.address);
    const FPoap = await ethers.getContractFactory("Poap");
    // const contract = await upgrades.deployProxy(FPoap, ["FutureXPoap", "FutureXPoap", "https://futurex.dev/"], { initializer: 'initialize', kind: 'uups' });
    const contract = await upgrades.deployProxy(FPoap, ["FutureXPoap", "FutureXPoap", "https://futurex.dev/", []], { initializer: '__POAP_init' });

    await contract.deployed();

    // let ownerBalance = await nft.balanceOf(owner.address);
    // console.log(`You have balance ${ownerBalance}`);
    // nft.mintNFT(owner.address, "You see me?")
    // ownerBalance = await nft.balanceOf(owner.address);
    // console.log(`You have balance ${ownerBalance} now`);
  });
});