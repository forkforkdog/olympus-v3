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
}
