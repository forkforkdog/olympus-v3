// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./PreconditionsBase.sol";
import {IERC20} from "src/interfaces/IERC20.sol";
import {IYieldDepositFacility} from "src/policies/interfaces/deposits/IYieldDepositFacility.sol";
import {IDepositManager} from "src/policies/interfaces/deposits/IDepositManager.sol";
import {DEPOSv1} from "src/modules/DEPOS/DEPOS.v1.sol";

abstract contract PreconditionsYieldDepositFacility is PreconditionsBase {
    // Create position preconditions
    function createPositionPreconditions(
        uint256 assetSeed,
        uint8 periodMonthsSeed,
        uint256 amountSeed,
        bool wrapReceipt,
        bool wrapPosition
    ) internal returns (YDF_CreatePositionParams memory params) {
        // Get configured assets from deposit manager
        IERC20[] memory assets = depositManager.getConfiguredAssets();
        require(assets.length > 0, "No assets configured");

        // Filter assets that have vaults (yield bearing)
        IERC20[] memory yieldAssets = new IERC20[](assets.length);
        uint256 yieldCount = 0;

        for (uint256 i = 0; i < assets.length; i++) {
            IDepositManager.AssetConfiguration memory config = depositManager.getAssetConfiguration(
                assets[i]
            );
            if (config.isConfigured && address(config.vault) != address(0)) {
                yieldAssets[yieldCount] = assets[i];
                yieldCount++;
            }
        }

        require(yieldCount > 0, "No yield bearing assets configured");
        params.asset = yieldAssets[assetSeed % yieldCount];

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

        require(validCount > 0, "No valid periods for asset");
        params.periodMonths = validPeriods[periodMonthsSeed % validCount];

        // Set amount
        uint256 maxAmount = params.asset.balanceOf(currentActor);
        params.amount = fl.clamp(amountSeed, 1, maxAmount);

        params.wrapReceipt = wrapReceipt;
        params.wrapPosition = wrapPosition;
    }

    // Deposit preconditions (simpler version without position creation)
    function depositYDFPreconditions(
        uint256 assetSeed,
        uint8 periodMonthsSeed,
        uint256 amountSeed,
        bool wrapReceipt
    ) internal returns (YDF_DepositParams memory params) {
        // Get configured assets from deposit manager
        IERC20[] memory assets = depositManager.getConfiguredAssets();
        require(assets.length > 0, "No assets configured");

        // Filter assets that have vaults (yield bearing)
        IERC20[] memory yieldAssets = new IERC20[](assets.length);
        uint256 yieldCount = 0;

        for (uint256 i = 0; i < assets.length; i++) {
            IDepositManager.AssetConfiguration memory config = depositManager.getAssetConfiguration(
                assets[i]
            );
            if (config.isConfigured && address(config.vault) != address(0)) {
                yieldAssets[yieldCount] = assets[i];
                yieldCount++;
            }
        }

        require(yieldCount > 0, "No yield bearing assets configured");
        params.asset = yieldAssets[assetSeed % yieldCount];

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

        require(validCount > 0, "No valid periods for asset");
        params.periodMonths = validPeriods[periodMonthsSeed % validCount];

        // Set amount
        uint256 maxAmount = params.asset.balanceOf(currentActor);
        params.amount = fl.clamp(amountSeed, 1, maxAmount);

        params.wrapReceipt = wrapReceipt;
    }

    // Claim yield preconditions
    function claimYieldYDFPreconditions(
        uint256 positionIdSeed,
        uint256 numPositions,
        bool useTimestampHints
    ) internal returns (YDF_ClaimYieldParams memory params) {
        params.positionIds = new uint256[](1);
        params.positionIds[0] = positionIdSeed;
        if (useTimestampHints) {
            params.timestampHints = new uint48[](params.positionIds.length);
            for (uint256 i = 0; i < params.timestampHints.length; i++) {
                params.timestampHints[i] = uint48(block.timestamp - (i + 1) * 8 hours);
            }
        } else {
            params.timestampHints = new uint48[](params.positionIds.length);
        }
    }

    // Set yield fee preconditions
    function setYieldFeePreconditions(
        uint16 yieldFeeSeed
    ) internal returns (YDF_SetYieldFeeParams memory params) {
        // Must be <= 100e2 (100%)
        params.yieldFee = uint16(fl.clamp(yieldFeeSeed, 0, 100e2));
    }
}
