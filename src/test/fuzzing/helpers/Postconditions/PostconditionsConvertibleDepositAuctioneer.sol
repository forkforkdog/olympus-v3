// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./PostconditionsBase.sol";
import {IERC20} from "src/interfaces/IERC20.sol";
import {IConvertibleDepositAuctioneer} from "src/policies/interfaces/deposits/IConvertibleDepositAuctioneer.sol";

contract PostconditionsConvertibleDepositAuctioneer is PostconditionsBase {
    // Postconditions for bid
    function bidPostconditions(
        bool success,
        bytes memory returnData,
        BidParams memory params
    ) internal {
        _after();

        if (success) {
            (uint256 ohmOut, uint256 positionId, uint256 receiptTokenId) = abi.decode(
                returnData,
                (uint256, uint256, uint256)
            );
            onSuccessInvariantsGeneral(returnData);
        } else {
            onFailInvariantsGeneral(returnData);
        }
    }

    function enableDepositPeriodPostconditions(
        bool success,
        bytes memory returnData,
        EnableDepositPeriodParams memory params
    ) internal {
        _after();

        if (success) {
            onSuccessInvariantsGeneral(returnData);
        } else {
            onFailInvariantsGeneral(returnData);
        }
    }

    function disableDepositPeriodPostconditions(
        bool success,
        bytes memory returnData,
        DisableDepositPeriodParams memory params
    ) internal {
        _after();

        if (success) {
            onSuccessInvariantsGeneral(returnData);
        } else {
            onFailInvariantsGeneral(returnData);
        }
    }

    function setAuctionParametersPostconditions(
        bool success,
        bytes memory returnData,
        SetAuctionParametersParams memory params
    ) internal {
        _after();

        if (success) {
            onSuccessInvariantsGeneral(returnData);
        } else {
            onFailInvariantsGeneral(returnData);
        }
    }

    function setTickStepPostconditions(
        bool success,
        bytes memory returnData,
        SetTickStepParams memory params
    ) internal {
        _after();

        if (success) {
            onSuccessInvariantsGeneral(returnData);
        } else {
            onFailInvariantsGeneral(returnData);
        }
    }

    function setAuctionTrackingPeriodPostconditions(
        bool success,
        bytes memory returnData,
        SetAuctionTrackingPeriodParams memory params
    ) internal {
        _after();

        if (success) {
            onSuccessInvariantsGeneral(returnData);
        } else {
            onFailInvariantsGeneral(returnData);
        }
    }
}
