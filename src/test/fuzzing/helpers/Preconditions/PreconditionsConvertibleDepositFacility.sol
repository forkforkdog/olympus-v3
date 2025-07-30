// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./PreconditionsBase.sol";

import {IERC20} from "src/interfaces/IERC20.sol";
import {IConvertibleDepositFacility} from "src/policies/interfaces/deposits/IConvertibleDepositFacility.sol";
import {IDepositManager} from "src/policies/interfaces/deposits/IDepositManager.sol";
import {DEPOSv1} from "src/modules/DEPOS/DEPOS.v1.sol";

contract PreconditionsConvertibleDepositFacility is PreconditionsBase {
    // Create position preconditions (requires ROLE_AUCTIONEER)
    function createPositionPreconditions(
        uint256 assetSeed,
        uint8 periodMonthsSeed,
        uint256 amountSeed,
        uint256 conversionPriceSeed,
        bool wrapPosition,
        bool wrapReceipt
    ) internal returns (CDF_CreatePositionParams memory params) {
        // Get configured assets from deposit manager
        IERC20[] memory assets = depositManager.getConfiguredAssets();
        require(assets.length > 0, "No assets configured"); //TODO: remove require
        params.asset = assets[assetSeed % assets.length];

        // Get valid periods for the asset
        IDepositManager.AssetPeriod[] memory periods = depositManager.getAssetPeriods();
        uint8[] memory validPeriods = new uint8[](periods.length);
        uint256 validCount = 0;

        for (uint256 i = 0; i < periods.length; i++) {
            //TODO: switch to hardroded values
            if (address(periods[i].asset) == address(params.asset) && periods[i].isEnabled) {
                validPeriods[validCount] = periods[i].depositPeriod;
                validCount++;
            }
        }

        require(validCount > 0, "No valid periods for asset"); //TODO: remove require
        params.periodMonths = validPeriods[periodMonthsSeed % validCount];

        params.depositor = currentActor;

        uint256 maxAmount = params.asset.balanceOf(params.depositor); //NOTE: not checking erc20 correctness
        params.amount = fl.clamp(amountSeed, 1, maxAmount);

        // function _previewConvert(
        //     uint256 amount_,
        //     uint256 conversionPrice_
        // ) internal pure returns (uint256) {
        //     // amount_ and conversionPrice_ are in the same decimals and cancel each other out
        //     // The output needs to be in OHM, so we multiply by 1e9
        //     // This also deliberately rounds down
        //     return (amount_ * 1e9) / conversionPrice_;
        // }

        params.conversionPrice = 1e9; //TODO: introduce randomization

        params.wrapPosition = wrapPosition;
        params.wrapReceipt = wrapReceipt;
    }

    // Deposit preconditions
    function depositCDFPreconditions(
        uint256 assetSeed,
        uint8 periodMonthsSeed,
        uint256 amountSeed,
        bool wrapReceipt
    ) internal returns (CDF_DepositParams memory params) {
        // Get configured assets from deposit manager
        IERC20[] memory assets = depositManager.getConfiguredAssets();
        require(assets.length > 0, "No assets configured"); //TODO: remove require
        params.asset = assets[assetSeed % assets.length];

        // Get valid periods for the asset
        IDepositManager.AssetPeriod[] memory periods = depositManager.getAssetPeriods();
        uint8[] memory validPeriods = new uint8[](periods.length);
        uint256 validCount = 0;

        for (uint256 i = 0; i < periods.length; i++) {
            if (address(periods[i].asset) == address(params.asset) && periods[i].isEnabled) {
                validPeriods[validCount] = periods[i].depositPeriod;
                validCount++;
            }
        }

        require(validCount > 0, "No valid periods for asset"); //TODO: remove require
        params.periodMonths = validPeriods[periodMonthsSeed % validCount];

        uint256 maxAmount = params.asset.balanceOf(currentActor); //NOTE: not checking erc20 correctness
        params.amount = fl.clamp(amountSeed, 1, maxAmount);

        params.wrapReceipt = wrapReceipt;
    }

    // Convert preconditions
    function convertPreconditions(
        uint256 positionIdSeed,
        uint256 amountSeed,
        bool wrappedReceipt
    ) internal returns (CDF_ConvertParams memory params) {
        uint256 numPositions = 1; // Single position for now

        params.positionIds = new uint256[](numPositions);
        params.amounts = new uint256[](numPositions);

        params.positionIds[0] = fl.clamp(positionIdSeed, 0, type(uint256).max);
        params.amounts[0] = fl.clamp(amountSeed, 0, type(uint256).max);

        params.wrappedReceipt = wrappedReceipt;
    }

    // Claim yield preconditions
    function claimYieldCDFPreconditions(
        uint256 assetSeed
    ) internal returns (CDF_ClaimYieldParams memory params) {
        // Get configured assets from deposit manager
        IERC20[] memory assets = depositManager.getConfiguredAssets();
        require(assets.length > 0, "No assets configured"); //TODO: remove require
        params.asset = assets[assetSeed % assets.length];
    }

    // Reclaim preconditions
    function reclaimCDFPreconditions(
        uint256 assetSeed,
        uint8 periodMonthsSeed,
        uint256 amountSeed
    ) internal returns (CDF_ReclaimParams memory params) {
        // Get configured assets from deposit manager
        IERC20[] memory assets = depositManager.getConfiguredAssets();
        require(assets.length > 0, "No assets configured"); //TODO: remove require
        params.asset = assets[assetSeed % assets.length];

        // Get valid periods for the asset
        IDepositManager.AssetPeriod[] memory periods = depositManager.getAssetPeriods();
        uint8[] memory validPeriods = new uint8[](periods.length);
        uint256 validCount = 0;

        for (uint256 i = 0; i < periods.length; i++) {
            if (address(periods[i].asset) == address(params.asset) && periods[i].isEnabled) {
                validPeriods[validCount] = periods[i].depositPeriod;
                validCount++;
            }
        }

        params.amount = fl.clamp(amountSeed, 0, type(uint256).max);
    }
}
