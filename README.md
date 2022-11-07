<div align="center">
  <h1>FutureX POAPs</h1>
  <p>
    <a href="https://github.com/futurex-dev/FutureX-POAPs/actions?query=workflow%3Atest">
      <img src="https://github.com/futurex-dev/FutureX-POAPs/actions/workflows/main.yml/badge.svg">
    </a>
    <a href="https://codecov.io/gh/futurex-dev/FutureX-POAPs" >
      <img src="https://codecov.io/gh/futurex-dev/FutureX-POAPs/branch/main/graph/badge.svg?token=3MFLA63A1L"/>
    </a>
  </p>
</div>

## Core functions

*API not stable yet.*

**C**reat **R**ead **U**pdate **D**elete:

* **C**: Add Event - `creatEvent`

* **C**: Add Event Organizer - `addEventMinter`
* **C**: Add admin - `addAdmin`
* **C**: Mint token *for* an event - `mintToken`
* **C**: Batch Mint - `mintEventToManyUsers`
* **R**: view all poaps for one user - (`balanceOf`, then `eventOfOwnerByIndex`)
* **R**: view all users *for* one event - (`balanceOfEvent`, then `userOfEventByIndex`)
* **R**: view user role - `isEventMinter`, `isEventCreator`, `isAdmin`
* **R**: view event infos - `eventHasUser`, `eventMetaURI`
* **U**: Pause or un-pause contract - `pause`, `unpause`
* **U**: Authorize or un-authorize contract - `authorize`, `unauthorize`
* **D**: Burn Tokens - `burn`
*    : ERC721 interfaces - (base, URI, enumerable)

Checkout `test/Poap.js` for more details.

## Deploy to local

1. Enable your local blockchain with command `npx hardhat node` first, and let this session stay opened.

2. Run command `npx hardhat deploy-poap --network localhost` to deploy the Poaps. It shall output the proxy contract address [ADDRESS].

3. Interact with the contract using `npx hardhat console --network localhost`

   ```javascript
   > const Poap = await ethers.getContractFactory("Poap")
   > const poap = await Poap.attach("[ADDRESS]")
   > await poap.name()
   ...
   ```

4. Stay the above console opened, you can update the contract functions under `contracts/*` and use `npx hardhat upgrade-poap --network localhost [ADDRESS] ` to upgrade. You can then continue testing the functions with `poap` object in step.3

## Commands  

```shell
npx hardhat compile # compile contracts to artifacts
npx hardhat test # test the contracts using test/*.js 
REPORT_GAS=true npx hardhat test # estimate the contracts gas fee. Extremly SLOW

npx hardhat run scripts/deploy.js --network XXX # not ready yet
```



## Acknowledgement

Thanks to the great open-sourced POAPs [contract](https://github.com/poap-xyz/poap-contracts) from [poap.xyz](https://github.com/poap-xyz) !
