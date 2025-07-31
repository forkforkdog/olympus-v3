// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./helpers/Preconditions/PreconditionsConvertibleDepositFacility.sol";
import "./helpers/Postconditions/PostconditionsConvertibleDepositFacility.sol";
import {IERC20} from "src/interfaces/IERC20.sol";
import {IConvertibleDepositFacility} from "src/policies/interfaces/deposits/IConvertibleDepositFacility.sol";
import {BaseDepositFacility} from "src/policies/deposits/BaseDepositFacility.sol";

contract FuzzConvertibleDepositFacility is
    PreconditionsConvertibleDepositFacility,
    PostconditionsConvertibleDepositFacility
{
    function fuzz_createPosition(
        uint256 assetSeed,
        uint8 periodMonthsSeed,
        uint256 amountSeed,
        uint256 conversionPriceSeed,
        bool wrapPosition,
        bool wrapReceipt
    ) public setCurrentActor {
        CDF_CreatePositionParams memory params = createPositionPreconditions(
            assetSeed,
            periodMonthsSeed,
            amountSeed,
            conversionPriceSeed,
            wrapPosition,
            wrapReceipt
        );

        _before();

        (bool success, bytes memory returnData) = fl.doFunctionCall(
            address(convertibleDepositFacility),
            abi.encodeWithSelector(
                IConvertibleDepositFacility.createPosition.selector,
                IConvertibleDepositFacility.CreatePositionParams({
                    asset: params.asset,
                    periodMonths: params.periodMonths,
                    depositor: params.depositor,
                    amount: params.amount,
                    conversionPrice: params.conversionPrice,
                    wrapPosition: params.wrapPosition,
                    wrapReceipt: params.wrapReceipt
                })
            ),
            currentActor
        );

        createPositionPostconditions(success, returnData, params);
    }

    function fuzz_CDF_deposit(
        uint256 assetSeed,
        uint8 periodMonthsSeed,
        uint256 amountSeed,
        bool wrapReceipt
    ) public setCurrentActor {
        CDF_DepositParams memory params = depositCDFPreconditions(
            assetSeed,
            periodMonthsSeed,
            amountSeed,
            wrapReceipt
        );

        _before();

        (bool success, bytes memory returnData) = fl.doFunctionCall(
            address(convertibleDepositFacility),
            abi.encodeWithSelector(
                IConvertibleDepositFacility.deposit.selector,
                params.asset,
                params.periodMonths,
                params.amount,
                params.wrapReceipt
            ),
            currentActor
        );

        depositPostconditions(success, returnData, params);
    }

    function fuzz_CDF_convert(
        uint256 positionIdSeed,
        uint256 amountSeed,
        bool wrappedReceipt
    ) public setCurrentActor {
        CDF_ConvertParams memory params = convertPreconditions(
            positionIdSeed,
            amountSeed,
            wrappedReceipt
        );

        _before();

        (bool success, bytes memory returnData) = fl.doFunctionCall(
            address(convertibleDepositFacility),
            abi.encodeWithSelector(
                IConvertibleDepositFacility.convert.selector,
                params.positionIds,
                params.amounts,
                params.wrappedReceipt
            ),
            currentActor
        );

        convertPostconditions(success, returnData, params);
    }

    function fuzz_CDF_claimYield(uint256 assetSeed) public setCurrentActor {
        CDF_ClaimYieldParams memory params = claimYieldCDFPreconditions(assetSeed);

        _before();

        (bool success, bytes memory returnData) = fl.doFunctionCall(
            address(convertibleDepositFacility),
            abi.encodeWithSelector(IConvertibleDepositFacility.claimYield.selector, params.asset),
            currentActor
        );

        claimYieldPostconditions(success, returnData, params);
    }

    function fuzz_CDF_claimAllYield() public setCurrentActor {
        _before();

        (bool success, bytes memory returnData) = fl.doFunctionCall(
            address(convertibleDepositFacility),
            abi.encodeWithSelector(IConvertibleDepositFacility.claimAllYield.selector),
            currentActor
        );

        claimAllYieldPostconditions(success, returnData);
    }

    //   function reclaim(
    //         IERC20 depositToken_,
    //         uint8 depositPeriod_,
    //         uint256 amount_
    //     ) external returns (uint256 reclaimed) {
    //         reclaimed = reclaimFor(depositToken_, depositPeriod_, msg.sender, amount_);
    //     }

    function fuzz_CDF_reclaim(
        uint256 assetSeed,
        uint8 periodMonthsSeed,
        uint256 amountSeed
    ) public setCurrentActor {
        CDF_ReclaimParams memory params = reclaimCDFPreconditions(
            assetSeed,
            periodMonthsSeed,
            amountSeed
        );

        _before();

        (bool success, bytes memory returnData) = fl.doFunctionCall(
            address(convertibleDepositFacility),
            abi.encodeWithSelector(
                BaseDepositFacility.reclaim.selector,
                params.asset,
                params.periodMonths,
                params.amount
            ),
            currentActor
        );

        reclaimPostconditions(success, returnData, params);
    }

    function fuzz_CDF_execute() public setCurrentActor {
        _before();

        (bool success, bytes memory returnData) = fl.doFunctionCall(
            address(convertibleDepositFacility),
            abi.encodeWithSelector(ConvertibleDepositFacility.execute.selector),
            HEART
        );

        executePostconditions(success, returnData);
    }
}
