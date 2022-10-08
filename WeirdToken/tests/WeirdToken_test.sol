// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.4.22 <0.9.0;

// This import is automatically injected
import "../.deps/tests.sol";

// This import is required to use custom transaction context
// Although it may fail compilation in 'Solidity Compiler' plugin
// But it will work fine in 'Solidity Unit Testing' plugin
import "../.deps/accounts.sol";
import "../contracts/WeirdToken.sol";

// File name has to end with '_test.sol', this file can contain more than one testSuite contracts
contract testSuite {
    // do not touch decimals = 18
    WeirdToken public weirdtoken;

    /// 'beforeAll' runs before all other tests
    /// More special functions are: 'beforeEach', 'beforeAll', 'afterEach' & 'afterAll'
    function beforeAll() public payable {
        weirdtoken = new WeirdToken(
            "Weird Token",
            "BURN",
            1000000000,
            TestsAccounts.getAccount(0)
        );
    }

    function checkTotalSupply() public {
        Assert.equal(
            weirdtoken.totalSupply(),
            1000000000 * 10**18,
            "total supply not equal"
        );
    }

    function checkSender() public payable {
        Assert.equal(msg.sender, TestsAccounts.getAccount(0), "Invalid sender");
        Assert.notEqual(
            msg.sender,
            TestsAccounts.getAccount(1),
            "Invalid sender - should be 0, not 1"
        );
    }

    // TODO: check how to test pause/unpause during unit test

    // function checkPause() public {
    //     weirdtoken.pause();
    //     Assert.ok(weirdtoken.paused(), "Token has not locked");
    // }

    // function checkTokenTransferOnPause() public {
    //     weirdtoken.transfer(TestsAccounts.getAccount(0), 2 * 10**18);
    //     Assert.equal(weirdtoken.balanceOf(TestsAccounts.getAccount(0)),0, "token is locked, should not transfer");
    // }

    // function checkTokenBurnOnPause() public {
    //     weirdtoken.burn(1 * 10**18);
    //     Assert.equal(weirdtoken.totalSupply(),1000000000 * 10**18, "token is locked, should not lose any coin yet");
    // }

    // function checkUnpause() public {
    //     weirdtoken.unpause();
    //     Assert.notEqual(weirdtoken.paused(), true, "Token is still locked");
    // }

    function checkTokenOnUnpause() public {
        weirdtoken.transfer(TestsAccounts.getAccount(0), 2 * 10**18);
        weirdtoken.transfer(TestsAccounts.getAccount(1), 2 * 10**18);
        weirdtoken.burn(1 * 10**18);
        Assert.equal(
            weirdtoken.balanceOf(TestsAccounts.getAccount(0)),
            1 * 10**18,
            "acc 0 balance should be 1"
        );
        Assert.equal(
            weirdtoken.balanceOf(TestsAccounts.getAccount(1)),
            1 * 10**18,
            "acc 1 balance should be 1"
        );
    }

    function checkTaxWorked() public {
        Assert.equal(
            weirdtoken.totalTax(),
            2 * 10**18,
            "2 transfers above 1 coin = 2 tax"
        );
    }

    function checkBalanceAfterTransfer() public {
        // 2 lost on transfer
        // 1 lost on burn
        // 1 lost on tax burn during transfer to self
        Assert.equal(
            (1) * 10**18,
            weirdtoken.balanceOf(TestsAccounts.getAccount(0)),
            "Min tax on transfer does not work"
        );
        Assert.equal(
            (1) * 10**18,
            weirdtoken.balanceOf(TestsAccounts.getAccount(1)),
            "Transfer taxed does not work"
        );
    }
}
