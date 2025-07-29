// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./PreconditionsBase.sol";
import {IERC20} from "src/interfaces/IERC20.sol";
import {IConvertibleDepositAuctioneer} from "src/policies/interfaces/deposits/IConvertibleDepositAuctioneer.sol";

contract PreconditionsConvertibleDepositAuctioneer is PreconditionsBase {
    // Bid function preconditions
    function bidPreconditions(
        uint8 depositPeriodSeed,
        uint256 depositAmountSeed,
        bool wrapPosition,
        bool wrapReceipt
    ) internal returns (BidParams memory params) {
        // Get enabled deposit periods
        uint8[] memory periods = auctioneer.getDepositPeriods();
        require(periods.length > 0, "No deposit periods configured");

        // Find enabled periods
        uint8[] memory enabledPeriods = new uint8[](periods.length);
        uint256 enabledCount = 0;

        for (uint256 i = 0; i < periods.length; i++) {
            if (auctioneer.isDepositPeriodEnabled(periods[i])) {
                enabledPeriods[enabledCount] = periods[i];
                enabledCount++;
            }
        }

        require(enabledCount > 0, "No enabled deposit periods");
        params.depositPeriod = enabledPeriods[depositPeriodSeed % enabledCount];

        // Get deposit asset and set amount
        IERC20 depositAsset = auctioneer.getDepositAsset();
        uint256 maxAmount = depositAsset.balanceOf(currentActor);
        params.depositAmount = fl.clamp(depositAmountSeed, 1, maxAmount);

        params.wrapPosition = wrapPosition;
        params.wrapReceipt = wrapReceipt;
    }

    // Enable deposit period preconditions
    function enableDepositPeriodPreconditions(
        uint8 depositPeriodSeed
    ) internal returns (EnableDepositPeriodParams memory params) {
        params.depositPeriod = depositPeriodSeed;
    }

    // Disable deposit period preconditions
    function disableDepositPeriodPreconditions(
        uint8 depositPeriodSeed
    ) internal returns (DisableDepositPeriodParams memory params) {
        // Get enabled deposit periods
        uint8[] memory periods = auctioneer.getDepositPeriods();
        uint8[] memory enabledPeriods = new uint8[](periods.length);
        uint256 enabledCount = 0;

        for (uint256 i = 0; i < periods.length; i++) {
            if (auctioneer.isDepositPeriodEnabled(periods[i])) {
                enabledPeriods[enabledCount] = periods[i];
                enabledCount++;
            }
        }

        if (enabledCount == 0) {
            params.depositPeriod = 0; // Will fail
        } else {
            params.depositPeriod = enabledPeriods[depositPeriodSeed % enabledCount];
        }
    }

    // Set auction parameters preconditions
    function setAuctionParametersPreconditions(
        uint256 targetSeed,
        uint256 tickSizeSeed,
        uint256 minPriceSeed
    ) internal returns (SetAuctionParametersParams memory params) {
        params.target = targetSeed;
        params.tickSize = tickSizeSeed;
        params.minPrice = minPriceSeed;
    }

    // Set tick step preconditions
    function setTickStepPreconditions(
        uint24 tickStepSeed
    ) internal returns (SetTickStepParams memory params) {
        params.newStep = tickStepSeed;
    }

    // Set auction tracking period preconditions
    function setAuctionTrackingPeriodPreconditions(
        uint8 daysSeed
    ) internal returns (SetAuctionTrackingPeriodParams memory params) {
        params.daysNumber = daysSeed;
    }
}
