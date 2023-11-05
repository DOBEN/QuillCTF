## Capture the Flag Challenge `StakeKing`

https://quillctf.super.site/challenges/quillctf-challenges-1/stakeking

## Prerequisites

This project uses `foundry` (https://book.getfoundry.sh/) which needs to be set up.

## Running the project

Run the following commands to install dependencies:
```
forge install foundry-rs/forge-std
forge install openzeppelin/openzeppelin-contracts
```

Run the following command to compile the contracts:
```
forge build
```

Run the following command to run the tests:
```
forge test
```

## Capture the Flag Challenge `StakeKing`
 
Anybody can call the function `stakeKing.claimInterest()` after staking some tokens. The reward payouts are paid by using Alice staked tokens. If the hacker waits long enough (not too long) after staking its tokens, the hacker can call the function `stakeKing.claimInterest()` and all 100 staked tokens from Alice have been used as reward payout. The hacker got most of these rewards but a small amount of tokens are transferred to the `feeManager` smart contract. After the hacker withdraws their staked tokens, the hacker still needs to get access to the tokens on the `feeManager` smart contract. This can be done with:

```
feeManager.sendMsg(
    address(usdc),
    abi.encodeWithSignature("transfer(address,uint256)", Hacker, 40)
);
```
