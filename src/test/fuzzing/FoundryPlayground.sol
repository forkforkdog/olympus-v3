// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./FuzzGuided.sol";

contract FoundryPlayground is FuzzGuided {
    function setUp() public {
        vm.warp(1524785992); //echidna starting time
        fuzzSetup();
    }

    function test_basic() public {
        assert(false);
    }

    function test_coverage_CDF_convert() public {
        setActor(USERS[0]);
        fuzz_bid(0, 10e18, false, false);

        setActor(USERS[0]);
        fuzz_CDF_convert(0, 1e18, false);
    }

    function test_coverage_CDF_reclaim() public {
        setActor(USERS[0]);
        fuzz_bid(0, 10e18, false, false);

        setActor(USERS[0]);
        fuzz_CDF_reclaim(0, 0, 10e18);
    }

    function test_coverage_YDF_createPosition() public {
        setActor(USERS[1]);
        fuzz_YDF_createPosition(0, 0, 10e18, false, false);
        setActor(USERS[1]);
        fuzz_YDF_claimYield(0, 1, false);
    }

    function test_coverage_DRV_startRedemption() public {
        // First create a position to get receipt tokens
        setActor(USERS[0]);
        fuzz_bid(0, 10e18, false, false);

        // Then start redemption
        setActor(USERS[0]);
        fuzz_DRV_startRedemption(0, 0, 5e18, 0);
    }

    function test_coverage_DRV_cancelRedemption() public {
        // First create a position to get receipt tokens
        setActor(USERS[0]);
        fuzz_bid(0, 10e18, false, false);

        // Start redemption
        setActor(USERS[0]);
        fuzz_DRV_startRedemption(0, 0, 5e18, 0);

        // Cancel redemption
        setActor(USERS[0]);
        fuzz_DRV_cancelRedemption(0, 2e18);
    }

    function test_coverage_DRV_finishRedemption() public {
        // First create a position to get receipt tokens
        setActor(USERS[0]);
        fuzz_bid(0, 10e18, false, false);

        // Start redemption
        setActor(USERS[0]);
        fuzz_DRV_startRedemption(0, 0, 5e18, 0);

        // Warp time to redemption period
        vm.warp(block.timestamp + 365 days);

        // Finish redemption
        setActor(USERS[0]);
        fuzz_DRV_finishRedemption(0);
    }

    function test_coverage_DRV_borrowAgainstRedemption() public {
        // First create a position to get receipt tokens
        setActor(USERS[0]);
        fuzz_bid(0, 10e18, false, false);

        // Start redemption
        setActor(USERS[0]);
        fuzz_DRV_startRedemption(0, 0, 5e18, 0);

        // Borrow against redemption
        setActor(USERS[0]);
        fuzz_DRV_borrowAgainstRedemption(0);
    }

    function test_coverage_DRV_repayLoan() public {
        // First create a position to get receipt tokens
        setActor(USERS[0]);
        fuzz_bid(0, 10e18, false, false);

        // Start redemption
        setActor(USERS[0]);
        fuzz_DRV_startRedemption(0, 0, 5e18, 0);

        // Borrow against redemption
        setActor(USERS[0]);
        fuzz_DRV_borrowAgainstRedemption(0);

        // Repay part of the loan
        setActor(USERS[0]);
        fuzz_DRV_repayLoan(0, 2e18);
    }

    function test_coverage_DRV_extendLoan() public {
        // First create a position to get receipt tokens
        setActor(USERS[0]);
        fuzz_bid(0, 10e18, false, false);

        // Start redemption
        setActor(USERS[0]);
        fuzz_DRV_startRedemption(0, 0, 5e18, 0);

        // Borrow against redemption
        setActor(USERS[0]);
        fuzz_DRV_borrowAgainstRedemption(0);

        // Extend the loan
        setActor(USERS[0]);
        fuzz_DRV_extendLoan(0, 3);
    }

    function test_coverage_DRV_claimDefaultedLoan() public {
        // First create a position to get receipt tokens
        setActor(USERS[0]);
        fuzz_bid(0, 10e18, false, false);

        // Start redemption
        setActor(USERS[0]);
        fuzz_DRV_startRedemption(0, 0, 5e18, 0);

        // Borrow against redemption
        setActor(USERS[0]);
        fuzz_DRV_borrowAgainstRedemption(0);

        // Warp time past loan due date
        vm.warp(block.timestamp + 365 days);

        // Anyone can claim the defaulted loan
        setActor(USERS[1]);
        fuzz_DRV_claimDefaultedLoan(0, 0);
    }

    function test_coverage_CDF_execute() public {
        fuzz_CDF_execute();
    }
}
