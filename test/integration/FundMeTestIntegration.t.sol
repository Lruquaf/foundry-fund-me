// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";
import {FundFundMe, WithdrawFundMe} from "../../script/Interactions.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;

    address public USER = makeAddr("user");
    uint256 public constant STARTING_BALANCE = 1 ether;

    uint256 public constant SENDING_VALUE = 0.1 ether;
    uint256 public constant GAS_PRICE = 2;

    function setUp() external {
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        // default sender of foundry will deploy, fund and withdraw
    }

    function testUserCanFundAndOwnerWithdraw() public {
        FundFundMe fundFundMe = new FundFundMe();
        fundFundMe.fundFundMe(address(fundMe));

        WithdrawFundMe withdrawFundMe = new WithdrawFundMe();
        withdrawFundMe.withdrawFundMe(address(fundMe));

        assertEq(address(fundMe).balance, 0);
    }
}
