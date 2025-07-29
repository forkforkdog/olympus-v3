// SPDX-License-Identifier: UNTITLED
pragma solidity >=0.8.0;

import "./FuzzYieldDepositFacility.sol";
import "./FuzzConvertibleDepositFacility.sol";
import "./FuzzConvertibleDepositAuctioneer.sol";

contract FuzzGuided is
    FuzzYieldDepositFacility,
    FuzzConvertibleDepositFacility,
    FuzzConvertibleDepositAuctioneer
{}
