// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;

    address public USER = makeAddr("user");
    uint256 public constant STARTING_BALANCE = 1 ether;

    uint256 public constant SENDING_VALUE = 0.1 ether;
    uint256 public constant GAS_PRICE = 2;

    function setUp() external {
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    function testMinimumUsdIsFive() public view {
        uint256 minUsd = fundMe.MINIMUM_USD();
        assertEq(minUsd, 5e18);
        console.log("Minimum USD: ", minUsd);
    }

    function testOwnerIsMsgSender() public view {
        address owner = fundMe.getOwner();
        console.log("Owner: ", owner);
        console.log("msg.sender: ", msg.sender);
        assertEq(owner, msg.sender);
    }

    function testPriceFeedVersionIsAccurate() public view {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFailsWithoutEnoughETH() public {
        vm.expectRevert("You need to spend more ETH!");
        fundMe.fund();
    }

    modifier fundedByAUser() {
        vm.prank(USER);
        fundMe.fund{value: SENDING_VALUE}();
        _;
    }

    function testFundUpdatesFundedMapping() public fundedByAUser {
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SENDING_VALUE);
    }

    function testFundAddsFunderToFundersArray() public fundedByAUser {
        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    function testOnlyOwnerCanWithdraw() public fundedByAUser {
        vm.prank(USER);
        vm.expectRevert();
        fundMe.withdraw();
    }

    function testWithdrawWithASingleFunder() public fundedByAUser {
        // Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        // Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(endingOwnerBalance, startingFundMeBalance + startingOwnerBalance);
    }

    function testWithdrawWithMultipleFunders() public {
        // Arrange
        uint160 numberOfFunders = 10;
        for (uint160 i = 1; i <= numberOfFunders; i++) {
            hoax(address(i), STARTING_BALANCE);
            fundMe.fund{value: SENDING_VALUE}();
        }
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act
        uint256 startingGas = gasleft();
        vm.txGasPrice(GAS_PRICE);
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();
        uint256 endingGas = gasleft();
        uint256 gasUsed = startingGas - endingGas;
        console.log("Gas used: ", gasUsed);

        // Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assert(endingFundMeBalance == 0);
        assertEq(endingOwnerBalance, startingFundMeBalance + startingOwnerBalance);
    }

    function testWithdrawWithMultipleFundersCheaper() public {
        // Arrange
        uint160 numberOfFunders = 10;
        for (uint160 i = 1; i <= numberOfFunders; i++) {
            hoax(address(i), STARTING_BALANCE);
            fundMe.fund{value: SENDING_VALUE}();
        }
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act
        uint256 startingGas = gasleft();
        vm.txGasPrice(GAS_PRICE);
        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperWithdraw();
        vm.stopPrank();
        uint256 endingGas = gasleft();
        uint256 gasUsed = startingGas - endingGas;
        console.log("Gas used: ", gasUsed);

        // Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assert(endingFundMeBalance == 0);
        assertEq(endingOwnerBalance, startingFundMeBalance + startingOwnerBalance);
    }
}
