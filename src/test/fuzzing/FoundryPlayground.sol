// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./FuzzGuided.sol";

contract FoundryPlayground is FuzzGuided {
    function setUp() public {
        vm.warp(1524785992); //echidna starting time
        fuzzSetup(false);
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

        // Simulate yield generation by minting tokens to vault
        // Seeds below 70 will mint (generate yield), above 70 will burn
        fuzz_YDF_simulateYield(50, 0); // Will mint tokens (50 < 70)

        vm.warp(block.timestamp + 4 hours + 1);

        fuzz_YDF_execute();

        // Add more yield before first claim
        fuzz_YDF_simulateYield(30, 0); // Will mint tokens (30 < 70)

        setActor(USERS[1]);
        fuzz_YDF_claimYield(0, 1, false);

        // Generate more yield between claims
        fuzz_YDF_simulateYield(10, 0); // Will mint tokens (10 < 70)

        fuzz_YDF_execute();

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

    function test_repro_ERR_01_01() public {
        fuzz_CDF_deposit(90071522809433658105489141, 0, 118737265262325488894027078496514, false);
        fuzz_CDF_claimAllYield();
        fuzz_CDF_claimYield(0);
        fuzz_disableDepositPeriod(0);
        fuzz_CDF_deposit(
            145338425827532980977710848,
            0,
            15705207393113163161276411250528862668,
            false
        );
        fuzz_bid(0, 15312952355, false, false);
        fuzz_bid(0, 0, false, false);
        fuzz_CDF_convert(0, 22481894031095905978127, false);
        fuzz_YDF_createPosition(52914596029361425362330, 0, 88040122830455337578, false, false);
        fuzz_CDF_convert(0, 1, true);
    }
}
