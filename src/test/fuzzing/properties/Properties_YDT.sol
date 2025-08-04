pragma solidity >=0.8.0;

import "./Properties_ERR.sol";

contract Properties_YDT is Properties_ERR {
    // function invariant_YDT_01(uint256 positionId) public {
    //     fl.gt(
    //         states[1].positionLastYieldConversionRate[positionId],
    //         0,
    //         "YDF-01:positionLastYieldConversionRate should be greater than 0"
    //     );
    // }
    // function invariant_YDT_02(YDF_CreatePositionParams memory params, uint256 actualAmount) public {
    //     assertApproxEq(
    //         params.amount,
    //         actualAmount,
    //         1,
    //         "YDF-02: user receipt token received (ERC6909 DepositManager::_mint token) == deposited reserve token amount"
    //     );
    // }
    // function invariant_YDT_03(uint256 positionId) public {
    //     fl.t(
    //         !states[1].isConvertible[positionId],
    //         "YDF-03: YDF-created position should never be considered a CDF position"
    //     );bidPostconditions
    // }
    // function invariant_YDT_04(YDF_CreatePositionParams memory params) public {
    //     if (params.asset == reserveToken) {
    //         fl.eq(
    //             states[1].actorStates[currentActor].assetLiabilities,
    //             states[1].actorStates[currentActor].assetLiabilities + params.amount,
    //             "YDF-04: assetLiabilities should be equal to before + receipt token amount received for deposit"
    //         );
    //     }
    //     if (params.asset == reserveTokenTwo) {
    //         fl.eq(
    //             states[1].actorStates[currentActor].assetLiabilitiesTwo,
    //             states[1].actorStates[currentActor].assetLiabilitiesTwo + params.amount,
    //             "YDF-04: assetLiabilitiesTwo should be equal to before + receipt token amount received for deposit"
    //         );
    //     }
    // }
    // function invariant_YDT_05(YDF_ClaimYieldParams memory params, uint256 yieldMinusFee) public {
    //     address vault = DEPOSIT_MANAGER.getAssetConfiguration(params.asset).vault;
    //     if (address(vault) == address(0)) {
    //         uint256 totalYieldAmount = yieldMinusFee + yieldDepositFacility.getYieldFee();
    //         if (params.asset == reserveToken) {
    //             fl.eq(
    //                 states[1].depositManagerBalance,
    //                 states[0].depositManagerBalance - totalYieldAmount,
    //                 "YDT-05: DepositManager balance should be decreased by total yield amount when no vault configured"
    //             );
    //         } else if (params.asset == reserveTokenTwo) {
    //             fl.eq(
    //                 states[1].depositManagerBalanceTwo,
    //                 states[0].depositManagerBalanceTwo - totalYieldAmount,
    //                 "YDT-05: DepositManager balance should be decreased by total yield amount when no vault configured"
    //             );
    //         }
    //     } else {
    //         if (params.asset == reserveToken) {
    //             fl.eq(
    //                 states[1].vaultBalance,
    //                 states[0].vaultBalance - totalYieldAmount,
    //                 "YDT-05: Vault balance should be decreased by total yield amount when no vault configured"
    //             );
    //         } else if (params.asset == reserveTokenTwo) {
    //             fl.eq(
    //                 states[1].vaultBalanceTwo,
    //                 states[0].vaultBalanceTwo - totalYieldAmount,
    //                 "YDT-05: Vault balance should be decreased by total yield amount when no vault configured"
    //             );
    //         }
    //     }
    // }
    // function invariant_YDT_06(address[] memory actors) public {
    //     uint256 totalActorYieldPreviews = 0;
    //     for (uint256 i = 0; i < actors.length; i++) {
    //         address actor = actors[i];
    //         totalActorYieldPreviews += states[1].actorStates[actor].totalPreviewClaimYield;
    //     }
    //     fl.eq(
    //         totalActorYieldPreviews,
    //         totalYieldAccrued,
    //         "YDT-06: Sum of all actor yield previews should equal total yield accrued"
    //     );
    // }
}
