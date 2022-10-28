const { expect } = require("chai");
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { ethers, upgrades } = require("hardhat");


describe("Poap main test", function () {
  async function contractFixture() {
    const [owner, addr1, addr2] = await ethers.getSigners();
    const FPoap = await ethers.getContractFactory("Poap");
    const contract = await upgrades.deployProxy(FPoap, ["FutureXPoap", "FutureXPoap", "https://futurex.dev/", [addr1.address]], { initializer: '__POAP_init' });
    await contract.deployed();
    // Fixtures can return anything you consider useful for your tests
    return { owner, addr1, addr2, contract };
  }
  it("Should check POAPs' vars", async function () {
    const { owner, addr1, addr2, contract } = await loadFixture(contractFixture);
    // -------------------
    // Status checking
    expect(await contract.name()).to.equal("FutureXPoap");
    expect(await contract.symbol()).to.equal("FutureXPoap");
    expect(await contract.paused()).to.equal(false);
    expect(await contract.isAdmin(owner.address)).to.equal(true);
    expect(await contract.isAdmin(addr1.address)).to.equal(true);
    expect(await contract.isAdmin(addr2.address)).to.equal(false);
    expect(await contract.isEventMinter(1, owner.address)).to.equal(true);
    expect(await contract.isEventMinter(1, addr1.address)).to.equal(true);
    expect(await contract.isEventMinter(1, addr2.address)).to.equal(false);
  });
  it("Should check POAPs' funcs", async function () {
    const { owner, contract } = await loadFixture(contractFixture);
    // -------------------
    // Poap pause checking
    expect(await contract.paused()).to.equal(false);
    await contract.pause();
    expect(await contract.paused()).to.equal(true);
    await contract.unpause();
    expect(await contract.paused()).to.equal(false);
    // -------------------
    // Poap mint checking
    await contract.mintToken(1024, owner.address);
    expect(await contract.balanceOf(owner.address)).to.equal(1);
    const [tokenId, eventId] = await contract.tokenDetailsOfOwnerByIndex(owner.address, 0);
    expect(tokenId).to.equal(1);
    expect(eventId).to.equal(1024);
    // each event can only assign once to one user
    await expect(contract.mintToken(1024, owner.address)).to.be.revertedWith("Poap: already assigned the event");

  });
});