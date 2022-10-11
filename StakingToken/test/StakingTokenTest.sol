// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../contracts/StakingToken.sol";
import "./TestToken.sol";

contract ERC20Test is Test {
    StakingToken stakingtoken;
    MyToken testtoken;

    address bobby = address(1);
    address victor = address(2);
    address saul = address(3);

    function setUp() public {
        vm.prank(bobby);
        testtoken = new MyToken();
        stakingtoken = new StakingToken(address(testtoken));
    }

    function testInitialStateShouldPass() public {
        vm.prank(bobby);
        assertEq(
            address(stakingtoken.accepted_staking_token_address()),
            address(testtoken)
        );
        assertEqUint(stakingtoken.reward_rate(), 0);
        assertEqUint(stakingtoken.total_staked_tokens(), 0);
        assertEq(stakingtoken.owner(), address(bobby));
    }

    function testTransferAddressZeroFail() public {
        vm.expectRevert(abi.encodeWithSignature("StakingToken_CannotBeZero()"));
        stakingtoken.transfer(address(0), 10);
    }

    function testApproveAddressZeroFail() public {
        vm.expectRevert(abi.encodeWithSignature("StakingToken_CannotBeZero()"));
        stakingtoken.approve(address(0), 10);
    }

    function testTransferFromShouldFail() public {
        vm.expectRevert(
            abi.encodeWithSignature("StakingToken_InsufficientAllowance()")
        );
        stakingtoken.transferFrom(bobby, victor, 100);
    }

    function testIncreaseAllowanceShouldFail() public {
        vm.expectRevert(
            abi.encodeWithSignature("StakingToken_InsufficientAllowance()")
        );
        stakingtoken.increaseAllowance(victor, 1000);
    }

    function testDecreaseAllowanceShouldFail() public {
        vm.expectRevert(
            abi.encodeWithSignature("StakingToken_InsufficientAllowance()")
        );
        stakingtoken.decreaseAllowance(victor, 1000);
    }

    function testSetRewardRateShouldFailNotOwner() public {
        vm.expectRevert(abi.encodeWithSignature("StakingToken_NotOwner()"));
        stakingtoken.setRewardRate(100);
    }

    function testMintShouldPass() public {
        vm.prank(bobby);
        testtoken.mint(bobby, 10000000000);
        assertEqUint(testtoken.balanceOf(bobby), 10000000000);
    }

    function testApprovalShouldPass() public {
        vm.startPrank(bobby);
        testtoken.mint(bobby, 100);
        testtoken.approve(victor, 100);
        vm.stopPrank();
        assertEqUint(testtoken.allowance(bobby, victor), 100);
    }

    function testIncreaseAllowanceShouldPass() public {
        vm.startPrank(bobby);
        testtoken.mint(bobby, 200);
        testtoken.approve(victor, 100);
        testtoken.increaseAllowance(victor, 100);
        vm.stopPrank();
        assertEqUint(testtoken.allowance(bobby, victor), 200);
    }

    function testDecreaseAllowanceShouldPass() public {
        vm.startPrank(bobby);
        testtoken.mint(bobby, 200);
        testtoken.approve(victor, 100);
        testtoken.decreaseAllowance(victor, 80);
        vm.stopPrank();
        assertEqUint(testtoken.allowance(bobby, victor), 20);
    }

    function testStakeShouldPass() public {
        vm.prank(bobby);
        testtoken.mint(bobby, 10000000000);
        testtoken.approve(address(stakingtoken), 10000000000);
        stakingtoken.depositStake(10000);
        assertEqUint(stakingtoken.totalSupply(), 0);
        assertEqUint(stakingtoken.getStakedBalance(), 10000);
    }

    function testStakeWithdrawWithRewardShouldPass() public {
        vm.startPrank(bobby);
        vm.warp(1665504000);
        testtoken.mint(bobby, 10000000000);
        testtoken.approve(address(stakingtoken), 10000000000);
        stakingtoken.setRewardRate(100);
        stakingtoken.depositStake(10000);
        vm.stopPrank();
        vm.warp(1665504001);
        assertEqUint(stakingtoken.getClaimableReward(), 100);
        assertEqUint(stakingtoken.totalSupplyPending(), 100);
        assertEqUint(stakingtoken.totalSupply(), 0);
        vm.prank(bobby);
        stakingtoken.withdrawStake(1000);
        assertEqUint(stakingtoken.getStakedBalance(), 9000);
        assertEqUint(stakingtoken.balanceOf(bobby), 100);
        assertEqUint(stakingtoken.totalSupply(), 100);
    }

    function testSetRewardStateShouldPass() public {
        vm.startPrank(bobby);
        stakingtoken.setRewardRate(100);
        vm.stopPrank();
        assertEqUint(stakingtoken.reward_rate(), 100);
    }

    function testRewardWithdrawWithRewardShouldPass() public {
        vm.startPrank(bobby);
        vm.warp(1665504000);
        testtoken.mint(bobby, 10000000000);
        testtoken.approve(address(stakingtoken), 10000000000);
        testtoken.transfer(victor, 10000);
        stakingtoken.setRewardRate(100);
        stakingtoken.depositStake(10000);
        vm.warp(1665504001);
        vm.stopPrank();
        assertEqUint(stakingtoken.getClaimableReward(), 100);
        assertEqUint(stakingtoken.totalSupplyPending(), 100);
        assertEqUint(stakingtoken.totalSupply(), 0);
        vm.startPrank(bobby);
        stakingtoken.withdrawReward(100);
        stakingtoken.withdrawRewardTo(100, saul);
        assertEqUint(stakingtoken.getStakedBalance(), 10000);
        vm.stopPrank();
        vm.startPrank(victor);
        testtoken.approve(address(stakingtoken), 10000000000);
        stakingtoken.depositStake(10000);
        vm.warp(1665504002);
        vm.stopPrank();
        assertEqUint(stakingtoken.getStakedBalance(), 10000);
        assertEqUint(stakingtoken.balanceOf(bobby), 100);
        assertEqUint(stakingtoken.balanceOf(saul), 100);
        assertEqUint(stakingtoken.balanceOf(victor), 0);
        assertEqUint(stakingtoken.totalSupply(), 200);
        assertEqUint(stakingtoken.total_staked_tokens(), 20000);
    }
}
