const { expect } = require("chai");

describe("Gus NFT", function () {
  it("Should deploy an NFT", async function () {
    const [owner] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", owner.address);
    const NFT = await ethers.getContractFactory("GusNFT");
    const nft = await NFT.deploy();
    await nft.deployed();

    let ownerBalance = await nft.balanceOf(owner.address);
    console.log(`You have balance ${ownerBalance}`);
    nft.mintNFT(owner.address, "You see me?")
    ownerBalance = await nft.balanceOf(owner.address);
    console.log(`You have balance ${ownerBalance} now`);
    // expect(await nft.totalSupply()).to.equal(ownerBalance);
  });
});