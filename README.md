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
  <p> <i> Adapted from <a href="https://github.com/poap-xyz/poap-contracts">poap-xyz/poap-contracts</a></i></p>
</div>

## Core functions

*API not stable yet.*

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
