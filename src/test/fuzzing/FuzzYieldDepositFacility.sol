// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./helpers/Preconditions/PreconditionsYieldDepositFacility.sol";
import "./helpers/Postconditions/PostconditionsYieldDepositFacility.sol";
import {IERC20} from "src/interfaces/IERC20.sol";
import {IYieldDepositFacility} from "src/policies/interfaces/deposits/IYieldDepositFacility.sol";

contract FuzzYieldDepositFacility is
    PreconditionsYieldDepositFacility,
    PostconditionsYieldDepositFacility
{
    function fuzz_createPosition(
        uint256 assetSeed,
        uint8 periodMonthsSeed,
        uint256 amountSeed,
        bool wrapReceipt,
        bool wrapPosition
    ) public setCurrentActor {
        YDF_CreatePositionParams memory params = createPositionPreconditions(
            assetSeed,
            periodMonthsSeed,
            amountSeed,
            wrapReceipt,
            wrapPosition
        );

        _before();

        (bool success, bytes memory returnData) = fl.doFunctionCall(
            address(yieldDepositFacility),
            abi.encodeWithSelector(
                IYieldDepositFacility.createPosition.selector,
                IYieldDepositFacility.CreatePositionParams({
                    asset: params.asset,
                    periodMonths: params.periodMonths,
                    amount: params.amount,
                    wrapReceipt: params.wrapReceipt,
                    wrapPosition: params.wrapPosition
                })
            ),
            currentActor
        );

        createPositionPostconditions(success, returnData, params);
    }

    function fuzz_YDF_deposit(
        uint256 assetSeed,
        uint8 periodMonthsSeed,
        uint256 amountSeed,
        bool wrapReceipt
    ) public setCurrentActor {
        YDF_DepositParams memory params = depositYDFPreconditions(
            assetSeed,
            periodMonthsSeed,
            amountSeed,
            wrapReceipt
        );

        _before();

        (bool success, bytes memory returnData) = fl.doFunctionCall(
            address(yieldDepositFacility),
            abi.encodeWithSelector(
                IYieldDepositFacility.deposit.selector,
                params.asset,
                params.periodMonths,
                params.amount,
                params.wrapReceipt
            ),
            currentActor
        );

        depositPostconditions(success, returnData, params);
    }

    function fuzz_YDF_claimYield(
        uint256 positionIdSeed,
        uint256 numPositions,
        bool useTimestampHints
    ) public setCurrentActor {
        YDF_ClaimYieldParams memory params = claimYieldYDFPreconditions(
            positionIdSeed,
            numPositions,
            useTimestampHints
        );

        _before();

        (bool success, bytes memory returnData) = fl.doFunctionCall(
            address(yieldDepositFacility),
            useTimestampHints && params.timestampHints.length > 0
                ? abi.encodeWithSelector(
                    bytes4(keccak256("claimYield(uint256[],uint48[])")),
                    params.positionIds,
                    params.timestampHints
                )
                : abi.encodeWithSelector(
                    bytes4(keccak256("claimYield(uint256[])")),
                    params.positionIds
                ),
            currentActor
        );

        claimYieldPostconditions(success, returnData, params);
    }

    function fuzz_YDF_setYieldFee(uint16 yieldFeeSeed) public setCurrentActor {
        YDF_SetYieldFeeParams memory params = setYieldFeePreconditions(yieldFeeSeed);

        _before();

        (bool success, bytes memory returnData) = fl.doFunctionCall(
            address(yieldDepositFacility),
            abi.encodeWithSelector(IYieldDepositFacility.setYieldFee.selector, params.yieldFee),
            currentActor
        );

        setYieldFeePostconditions(success, returnData, params);
    }

    function fuzz_YDF_execute() public setCurrentActor {
        _before();

        fl.doFunctionCall(
            address(yieldDepositFacility),
            abi.encodeWithSelector(YieldDepositFacility.execute.selector),
            currentActor
        );
    }
}
