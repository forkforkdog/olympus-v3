// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./helpers/Preconditions/PreconditionsConvertibleDepositAuctioneer.sol";
import "./helpers/Postconditions/PostconditionsConvertibleDepositAuctioneer.sol";
import {IERC20} from "src/interfaces/IERC20.sol";
import {IConvertibleDepositAuctioneer} from "src/policies/interfaces/deposits/IConvertibleDepositAuctioneer.sol";

contract FuzzConvertibleDepositAuctioneer is
    PreconditionsConvertibleDepositAuctioneer,
    PostconditionsConvertibleDepositAuctioneer
{
    function fuzz_bid(
        uint8 depositPeriodSeed,
        uint256 depositAmountSeed,
        bool wrapPosition,
        bool wrapReceipt
    ) public setCurrentActor {
        BidParams memory params = bidPreconditions(
            depositPeriodSeed,
            depositAmountSeed,
            wrapPosition,
            wrapReceipt
        );

        _before();

        (bool success, bytes memory returnData) = fl.doFunctionCall(
            address(auctioneer),
            abi.encodeWithSelector(
                IConvertibleDepositAuctioneer.bid.selector,
                params.depositPeriod,
                params.depositAmount,
                params.wrapPosition,
                params.wrapReceipt
            ),
            currentActor
        );

        bidPostconditions(success, returnData, params);
    }

    function fuzz_enableDepositPeriod(uint8 depositPeriodSeed) public setCurrentActor {
        EnableDepositPeriodParams memory params = enableDepositPeriodPreconditions(
            depositPeriodSeed
        );

        _before();

        (bool success, bytes memory returnData) = fl.doFunctionCall(
            address(auctioneer),
            abi.encodeWithSelector(
                IConvertibleDepositAuctioneer.enableDepositPeriod.selector,
                params.depositPeriod
            )
            // admin NOTE: calling from admin
        );

        enableDepositPeriodPostconditions(success, returnData, params);
    }

    function fuzz_disableDepositPeriod(uint8 depositPeriodSeed) public setCurrentActor {
        DisableDepositPeriodParams memory params = disableDepositPeriodPreconditions(
            depositPeriodSeed
        );

        _before();

        (bool success, bytes memory returnData) = fl.doFunctionCall(
            address(auctioneer),
            abi.encodeWithSelector(
                IConvertibleDepositAuctioneer.disableDepositPeriod.selector,
                params.depositPeriod
            )
            // admin NOTE: calling from admin
        );

        disableDepositPeriodPostconditions(success, returnData, params);
    }

    function fuzz_setAuctionParameters(
        uint256 targetSeed,
        uint256 tickSizeSeed,
        uint256 minPriceSeed
    ) public setCurrentActor {
        SetAuctionParametersParams memory params = setAuctionParametersPreconditions(
            targetSeed,
            tickSizeSeed,
            minPriceSeed
        );

        _before();

        (bool success, bytes memory returnData) = fl.doFunctionCall(
            address(auctioneer),
            abi.encodeWithSelector(
                IConvertibleDepositAuctioneer.setAuctionParameters.selector,
                params.target,
                params.tickSize,
                params.minPrice
            )
            // admin NOTE: calling from admin
        );

        setAuctionParametersPostconditions(success, returnData, params);
    }

    function fuzz_setTickStep(uint24 tickStepSeed) public setCurrentActor {
        SetTickStepParams memory params = setTickStepPreconditions(tickStepSeed);

        _before();

        (bool success, bytes memory returnData) = fl.doFunctionCall(
            address(auctioneer),
            abi.encodeWithSelector(
                IConvertibleDepositAuctioneer.setTickStep.selector,
                params.newStep
            )
            // admin NOTE: calling from admin
        );

        setTickStepPostconditions(success, returnData, params);
    }

    function fuzz_setAuctionTrackingPeriod(uint8 daysSeed) public setCurrentActor {
        SetAuctionTrackingPeriodParams memory params = setAuctionTrackingPeriodPreconditions(
            daysSeed
        );

        _before();

        (bool success, bytes memory returnData) = fl.doFunctionCall(
            address(auctioneer),
            abi.encodeWithSelector(
                IConvertibleDepositAuctioneer.setAuctionTrackingPeriod.selector,
                params.daysNumber
            )
            // admin NOTE: calling from admin
        );

        setAuctionTrackingPeriodPostconditions(success, returnData, params);
    }
}
