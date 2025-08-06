pragma solidity >=0.8.0;

import "./Properties_ERR.sol";
import {IDepositPositionManager} from "src/modules/DEPOS/IDepositPositionManager.sol";

contract Properties_YDT is Properties_ERR {
    function invariant_YDT_01(uint256 positionId) public {
        console.log("positionId", positionId);
        console.log(
            "states[1].positionLastYieldConversionRate[positionId]",
            states[1].positionLastYieldConversionRate[positionId]
        );
        fl.gt(
            states[1].positionLastYieldConversionRate[positionId],
            0,
            "YDF-01:positionLastYieldConversionRate should be greater than 0"
        );
    }

    function invariant_YDT_02(YDF_CreatePositionParams memory params, uint256 actualAmount) public {
        assertApproxEq(
            params.amount,
            actualAmount,
            1,
            "YDF-02: user receipt token received (ERC6909 DepositManager::_mint token) == deposited reserve token amount"
        );
    }

    function invariant_YDT_03(uint256 positionId) public {
        fl.t(
            !states[1].isConvertible[positionId],
            "YDF-03: YDF-created position should never be considered a CDF position"
        );
    }

    function invariant_YDT_04(YDF_CreatePositionParams memory params) public {
        if (address(params.asset) == address(reserveToken)) {
            fl.eq(
                states[1].YDT_assetLiabilitiesOne,
                states[0].YDT_assetLiabilitiesOne + params.amount,
                "YDF-04: assetLiabilities should be equal to before + receipt token amount received for deposit"
            );
        }
        if (address(params.asset) == address(reserveTokenTwo)) {
            fl.eq(
                states[1].YDT_assetLiabilitiesTwo,
                states[0].YDT_assetLiabilitiesTwo + params.amount,
                "YDF-04: assetLiabilitiesTwo should be equal to before + receipt token amount received for deposit"
            );
        }
    }

    function invariant_YDT_05(YDF_ClaimYieldParams memory params, uint256 yieldMinusFee) public {
        // Get the asset from the first position
        IDepositPositionManager.Position memory position = yieldDepositFacility.DEPOS().getPosition(
            params.positionIds[0]
        );
        address asset = position.asset;

        // Get the vault configuration for this asset
        address vault = depositManager.getAssetConfiguration(IERC20(asset)).vault;

        // Calculate the actual fee transferred to TRSRY from balance changes
        uint256 yieldFee = 0;
        if (address(asset) == address(reserveToken)) {
            yieldFee = states[1].trsryBalance - states[0].trsryBalance;
        } else if (address(asset) == address(reserveTokenTwo)) {
            yieldFee = states[1].trsryBalanceTwo - states[0].trsryBalanceTwo;
        }

        // Total yield amount is what was claimed plus the fee
        uint256 totalYieldAmount = yieldMinusFee + yieldFee;

        // Check balance changes based on vault configuration
        if (address(vault) == address(0)) {
            // No vault configured - assets come from DepositManager
            if (address(asset) == address(reserveToken)) {
                fl.eq(
                    states[1].depositManagerBalance,
                    states[0].depositManagerBalance - totalYieldAmount,
                    "YDT-05: DepositManager balance should be decreased by total yield amount when no vault configured"
                );
            } else if (address(asset) == address(reserveTokenTwo)) {
                fl.eq(
                    states[1].depositManagerBalanceTwo,
                    states[0].depositManagerBalanceTwo - totalYieldAmount,
                    "YDT-05: DepositManager balance (token2) should be decreased by total yield amount when no vault configured"
                );
            }
        } else {
            // Vault configured - assets come from vault
            if (address(asset) == address(reserveToken)) {
                fl.eq(
                    states[1].vaultBalance,
                    states[0].vaultBalance - totalYieldAmount,
                    "YDT-05: Vault balance should be decreased by total yield amount when vault configured"
                );
            } else if (address(asset) == address(reserveTokenTwo)) {
                fl.eq(
                    states[1].vaultBalanceTwo,
                    states[0].vaultBalanceTwo - totalYieldAmount,
                    "YDT-05: Vault balance (token2) should be decreased by total yield amount when vault configured"
                );
            }
        }
    }

    function invariant_YDT_06(YDF_ClaimYieldParams memory params) public {
        // Compare the change in sum of previews with the change in total yield accrued
        // This accounts for yield that was claimed during the action
        uint256 yieldClaimedByUsers = 0;
        if (states[0].sumAllActorYieldPreviews >= states[1].sumAllActorYieldPreviews) {
            yieldClaimedByUsers =
                states[0].sumAllActorYieldPreviews -
                states[1].sumAllActorYieldPreviews;
        }

        uint256 totalYieldReduction = 0;
        if (states[0].totalYieldAccrued >= states[1].totalYieldAccrued) {
            totalYieldReduction = states[0].totalYieldAccrued - states[1].totalYieldAccrued;
        }

        fl.eq(
            yieldClaimedByUsers,
            totalYieldReduction,
            "YDT-06: Yield claimed by users should equal reduction in total yield accrued"
        );
    }
}
