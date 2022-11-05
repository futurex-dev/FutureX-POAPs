const { expect } = require("chai");
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { ethers, upgrades } = require("hardhat");


describe("Poap main test", function () {
  async function contractFixture() {
    const [owner, addr1, addr2] = await ethers.getSigners();
    const baseURI = "https://futurex.dev/token/";
    const poapName = "FutureXPoap";
    const FPoap = await ethers.getContractFactory("Poap");
    const contract = await upgrades.deployProxy(FPoap, [poapName, poapName, "https://futurex.dev/token/", [addr1.address]], { initializer: '__POAP_init' });
    await contract.deployed();
    // Fixtures can return anything you consider useful for your tests
    return { owner, addr1, addr2, contract, baseURI, poapName };
  }

  async function unwrapCreateEvent(contract, eventName) {
    const eventId_response = await contract.createEvent(eventName);
    const eventId_receipt = await eventId_response.wait();
    const [EventAdded] = eventId_receipt.events;
    const { eventId } = EventAdded.args;
    return eventId;
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
    const eventId = await unwrapCreateEvent(contract, "https://futurex.dev/token/temp#1");
    expect(await contract.isEventMinter(eventId, owner.address)).to.equal(true);
    expect(await contract.isEventMinter(eventId, addr1.address)).to.equal(true);
    expect(await contract.isEventMinter(eventId, addr2.address)).to.equal(false);
  });
  it("Should check POAPEvent", async function () {
    const { owner, contract, addr2 } = await loadFixture(contractFixture);
    const eventId_init = 1
    // -------------------
    // Poap event checking
    await expect(contract.mintToken(eventId_init, "poap-event-test", owner.address)).to.be.revertedWith("Poap: event not exists");
    const eventId = await unwrapCreateEvent(contract.connect(addr2), "https://futurex.dev/token/anyone");
    expect(await contract.eventMetaURI(eventId)).to.equal("https://futurex.dev/token/anyone");
    expect(await contract.isEventMinter(eventId, addr2.address)).to.equal(true);
    expect(await contract.isAdmin(addr2.address)).to.equal(false);
    await contract.connect(addr2).mintToken(eventId, "poap-event-test", owner.address)
    expect(await contract.eventHasUser(eventId, owner.address)).to.equal(true);
    expect(await contract.tokenEvent(await contract.tokenOfOwnerByIndex(owner.address, 0))).to.equal(eventId);
  });
  it("Should check POAPRole", async function () {
    const { owner, contract, addr1, addr2 } = await loadFixture(contractFixture);

    const eventId = await unwrapCreateEvent(contract, "https://futurex.dev/token/temp#2");
    // -------------------
    // PoapRole admin
    await contract.connect(addr1).renounceAdmin(); // msg.send = addr1
    expect(await contract.isAdmin(addr1.address)).to.equal(false);
    await contract.addAdmin(addr1.address);
    expect(await contract.isAdmin(addr1.address)).to.equal(true);

    await contract.removeAdmin(addr1.address);
    expect(await contract.isAdmin(addr1.address)).to.equal(false);
    await contract.addAdmin(addr1.address);
    expect(await contract.isAdmin(addr1.address)).to.equal(true);
    // -------------------
    // PoapRole event minter
    expect(await contract.isEventMinter(eventId, addr2.address)).to.equal(false);
    await contract.addEventMinter(eventId, addr2.address);
    expect(await contract.isEventMinter(eventId, addr2.address)).to.equal(true);
    await contract.removeEventMinter(eventId, addr2.address);
    expect(await contract.isEventMinter(eventId, addr2.address)).to.equal(false);
    await contract.addEventMinter(eventId, addr2.address);
    expect(await contract.isEventMinter(eventId, addr2.address)).to.equal(true);
    await contract.connect(addr2).renounceEventMinter(eventId);
    expect(await contract.isEventMinter(eventId, addr2.address)).to.equal(false);
  });
  it("Should check POAP CRUD", async function () {
    const { owner, contract, addr1, addr2, baseURI } = await loadFixture(contractFixture);
    const afterBaseURI = baseURI + "semi-token/";

    const eventId = await unwrapCreateEvent(contract, "https://futurex.dev/token/temp#3");
    const eventId2 = await unwrapCreateEvent(contract, "https://futurex.dev/token/temp#4");
    async function checkPoap(address, baseURI, index, contract, shouldBalance, shouldId, shouldEvent) {
      expect(await contract.balanceOf(address)).to.equal(shouldBalance);
      const [tokenId, eventId] = await contract.tokenDetailsOfOwnerByIndex(address, index);
      expect(tokenId).to.equal(shouldId);
      expect(await contract.tokenURI(tokenId)).to.equal(baseURI + `poap-${shouldId}`);
      expect(eventId).to.equal(shouldEvent);
    }
    // -------------------
    // Poap mint checking
    await contract.mintToken(eventId, "poap-1", owner.address);
    await checkPoap(owner.address, baseURI, 0, contract, 1, 1, eventId)
    // each event can only assign once to one user
    await expect(contract.mintToken(eventId, "poap-2", owner.address)).to.be.revertedWith("Poap: already assigned the event");
    expect(await contract.balanceOfEvent(eventId)).to.equal(1);

    await contract.mintEventToManyUsers(eventId2, ["poap-2", "poap-3", "poap-4"], [owner.address, addr1.address, addr2.address]);
    await checkPoap(owner.address, baseURI, 1, contract, 2, 2, eventId2)
    await checkPoap(addr1.address, baseURI, 0, contract, 1, 3, eventId2)
    await checkPoap(addr2.address, baseURI, 0, contract, 1, 4, eventId2)
    expect(await contract.balanceOfEvent(eventId2)).to.equal(3);
    expect(await contract.userOfEventByIndex(eventId2, 0)).to.equal(owner.address);
    expect(await contract.userOfEventByIndex(eventId2, 1)).to.equal(addr1.address);
    expect(await contract.userOfEventByIndex(eventId2, 2)).to.equal(addr2.address);

    expect(await contract.eventOfOwnerByIndex(owner.address, 0)).to.equal(eventId);
    expect(await contract.eventOfOwnerByIndex(owner.address, 1)).to.equal(eventId2);


    await contract.burn(2); // burn (eventId, owner)
    await expect(contract.connect(addr2).burn(3)).to.be.revertedWith("Poap: no access to burn");
    await checkPoap(owner.address, baseURI, 0, contract, 1, 1, eventId)
    expect(await contract.balanceOfEvent(eventId2)).to.equal(2);

    await contract.setBaseURI(afterBaseURI);
    await checkPoap(owner.address, afterBaseURI, 0, contract, 1, 1, eventId)

  });

  it("Should check POAP pause", async function () {
    const { owner, contract, addr1, addr2, baseURI } = await loadFixture(contractFixture);
    const eventId = 1;
    await contract.pause();

    expect(await contract.paused()).to.equal(true);
    await expect(contract.createEvent("https://futurex.dev/token/temp#3")).to.be.revertedWith("Pausable: paused");
    await expect(contract.mintToken(eventId, "poap-1", owner.address)).to.be.revertedWith("Pausable: paused");
    await expect(contract.mintEventToManyUsers(eventId, ["poap-2", "poap-3"], [owner.address, addr1.address])).to.be.revertedWith("Pausable: paused");
    await expect(contract.burn(1)).to.be.revertedWith("Pausable: paused");

    await contract.unpause();
    expect(await contract.paused()).to.equal(false);
  });
  it("Should check POAP transfer", async function () {
    const { owner, contract, addr1, addr2, baseURI } = await loadFixture(contractFixture);
    const eventId = await unwrapCreateEvent(contract, "https://futurex.dev/token/temp#1");
    const eventId2 = await unwrapCreateEvent(contract, "https://futurex.dev/token/temp#2");

    await contract.mintToken(eventId, "poap-1", owner.address);
    await contract.mintToken(eventId2, "poap-2", addr1.address);
    await contract.mintToken(eventId2, "poap-3", addr2.address);

    expect(await contract.eventHasUser(eventId2, owner.address)).to.equal(false);
    await contract.connect(addr1).transferFrom(addr1.address, owner.address, 2);
    expect(await contract.balanceOf(owner.address)).to.equal(2);
    expect(await contract.balanceOf(addr1.address)).to.equal(0);
    expect(await contract.eventHasUser(eventId2, owner.address)).to.equal(true);
    expect(await contract.eventHasUser(eventId2, addr1.address)).to.equal(false);

    // unable
    await expect(contract.connect(addr2).transferFrom(addr2.address, owner.address, 3)).to.be.revertedWith("Poap: user already have this event");

  });
});