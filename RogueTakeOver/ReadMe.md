## Capture the Flag Challenge `RogueTakeOver`

https://quillctf.super.site/challenges/quillctf-challenges-1/rogue-takeover

## Prerequisites

This project uses `foundry` (https://book.getfoundry.sh/) which needs to be set up.

## Running the project

Run the following commands to install dependencies:
```
forge install foundry-rs/forge-std
```

Run the following command to compile the contracts:
```
forge build
```

Run the following command to run the tests:
```
forge test
```

## Solution

When compiling solidity code, a `jumpDest` opcode is added in front of a new function. This is necessary so that the program pointer can `jump` to the start of this function and execute it if your solidity code calls this function internally as well. The developer's intention was to pass in an actual function with the variable `_func` in `anyCall(uint _func, uint data)`. The intended behavior was to jump to the start of the function `_func` and execute it. But there exist other `jumpDest` values as well e.g. `if-else statements` introduce also `jumpDest` values. We use this knowledge to trick the solidity code to jump to a `jumpDest` location that was not intended by the developer.

The challenge can be solved by using the Remix debugger as the first step (and the foundry debugger as the second step). Calling the `transferOwnership` function with the deployer address and using the Remix debugger to analyze the stack, it can be figured out which `jumpDest` value the line 21 `owner = msg.sender;` has (it is 303). It can also be observed that `0x77` is on top of the stack just before the `msg.sender` is loaded on top of the stack in line 21. Getting `0x77` on top of the stack needs to be replicated when calling the `anyCall(uint _func, uint data)` function by using 303 for the `_func` value and 0x77 for the `data` value and the transaction executed successfully and changed the owner storage value in the contract. 

The observations done in the Remix debugger can be replicated with the built-in foundry debugger to find the corresponding values to pass the foundry tests. Calling the `transferOwnership` function with the deployer address and using the foundry debugger to analyze the stack, the two values `_func = 0x0ea` and `data = 0x93` can be found.

Command to use the foundry debugger on the `testHack` test case:

```
forge test --debug testHack
```