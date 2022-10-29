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
  it("Should check POAPPausable", async function () {
    const { owner, contract } = await loadFixture(contractFixture);
    // -------------------
    // Poap pause checking
    expect(await contract.paused()).to.equal(false);
    await contract.pause();
    expect(await contract.paused()).to.equal(true);
    await contract.unpause();
    expect(await contract.paused()).to.equal(false);

  });
  it("Should check POAPRole", async function () {
    const { owner, contract, addr1, addr2 } = await loadFixture(contractFixture);
    const EVENT = 256;
    // -------------------
    // PoapRole admin
    await contract.connect(addr1).renounceAdmin(); // msg.send = addr1
    expect(await contract.isAdmin(addr1.address)).to.equal(false);
    await contract.addAdmin(addr1.address);
    expect(await contract.isAdmin(addr1.address)).to.equal(true);
    // -------------------
    // PoapRole event minter
    expect(await contract.isEventMinter(EVENT, addr2.address)).to.equal(false);
    await contract.addEventMinter(EVENT, addr2.address);
    expect(await contract.isEventMinter(EVENT, addr2.address)).to.equal(true);
    await contract.removeEventMinter(EVENT, addr2.address);
    expect(await contract.isEventMinter(EVENT, addr2.address)).to.equal(false);
    await contract.addEventMinter(EVENT, addr2.address);
    expect(await contract.isEventMinter(EVENT, addr2.address)).to.equal(true);
    await contract.connect(addr2).renounceEventMinter(EVENT);
    expect(await contract.isEventMinter(EVENT, addr2.address)).to.equal(false);
  });
  it("Should check POAP mint", async function () {
    const { owner, contract, addr1, addr2 } = await loadFixture(contractFixture);
    const EVENT = 512;
    const EVENT2 = 1024;
    // -------------------
    // Poap mint checking
    await contract.mintToken(EVENT, owner.address);
    expect(await contract.balanceOf(owner.address)).to.equal(1);
    let [tokenId, eventId] = await contract.tokenDetailsOfOwnerByIndex(owner.address, 0);
    expect(tokenId).to.equal(1);
    expect(eventId).to.equal(EVENT);
    // each event can only assign once to one user
    await expect(contract.mintToken(EVENT, owner.address)).to.be.revertedWith("Poap: already assigned the event");

    await contract.mintEventToManyUsers(EVENT2, [owner.address, addr1.address]);
    expect(await contract.balanceOf(owner.address)).to.equal(2);
    [tokenId, eventId] = await contract.tokenDetailsOfOwnerByIndex(owner.address, 1);
    expect(tokenId).to.equal(2);
    expect(eventId).to.equal(EVENT2);
    expect(await contract.balanceOf(addr1.address)).to.equal(1);
    [tokenId, eventId] = await contract.tokenDetailsOfOwnerByIndex(addr1.address, 0);
    expect(tokenId).to.equal(3);
    expect(eventId).to.equal(EVENT2);

    await contract.mintUserToManyEvents([EVENT, EVENT2], addr2.address);
    expect(await contract.balanceOf(addr2.address)).to.equal(2);
    [tokenId, eventId] = await contract.tokenDetailsOfOwnerByIndex(addr2.address, 0);
    expect(tokenId).to.equal(4);
    expect(eventId).to.equal(EVENT);
    [tokenId, eventId] = await contract.tokenDetailsOfOwnerByIndex(addr2.address, 1);
    expect(tokenId).to.equal(5);
    expect(eventId).to.equal(EVENT2);

    await contract.burn(4); // burn (EVENT, addr2)
    expect(await contract.balanceOf(addr2.address)).to.equal(1);
    [tokenId, eventId] = await contract.tokenDetailsOfOwnerByIndex(addr2.address, 0);
    expect(tokenId).to.equal(5);
    expect(eventId).to.equal(EVENT2);

  });
});