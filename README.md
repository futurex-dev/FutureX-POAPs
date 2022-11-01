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

## Commands  

```shell
npx hardhat compile # compile contracts to artifacts
npx hardhat test # test the contracts using test/*.js 
REPORT_GAS=true npx hardhat test # estimate the contracts gas fee. Extremly SLOW

npx hardhat run scripts/deploy.js --network XXX # not ready yet
```
