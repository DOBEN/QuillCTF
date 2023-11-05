// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Vault.sol";

contract Challenge is Test {
    Vault public vault;
    address hacker;

    function setUp() public {
        vault = new Vault("BaoZang");
        hacker = makeAddr("hacker");
    }

    function testHack() public {
        vm.startPrank(hacker, hacker);
        // solution
        vault.anyCall(0x0ea, 0x93);
        vm.stopPrank();
        assertEq(vault.owner(), hacker);
    }
}
