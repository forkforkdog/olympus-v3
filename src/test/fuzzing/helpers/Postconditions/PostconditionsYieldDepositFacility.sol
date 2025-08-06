// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./PostconditionsBase.sol";
import "../BeforeAfter.sol";
import {IERC20} from "src/interfaces/IERC20.sol";
import {IYieldDepositFacility} from "src/policies/interfaces/deposits/IYieldDepositFacility.sol";

contract PostconditionsYieldDepositFacility is PostconditionsBase {
    // Define structs locally for YieldDepositFacility
    struct CreatePositionParams {
        IERC20 asset;
        uint8 periodMonths;
        uint256 amount;
        bool wrapReceipt;
        bool wrapPosition;
    }

    struct DepositParams {
        IERC20 asset;
        uint8 periodMonths;
        uint256 amount;
        bool wrapReceipt;
    }

    struct ClaimYieldParams {
        uint256[] positionIds;
        uint48[] timestampHints;
    }

    struct SetYieldFeeParams {
        uint16 yieldFee;
    }

    // Postconditions for createPosition
    function createPositionPostconditions(
        bool success,
        bytes memory returnData,
        YDF_CreatePositionParams memory params
    ) internal {
        if (success) {
            // Decode return values
            (uint256 positionId, uint256 receiptTokenId, uint256 actualAmount) = abi.decode(
                returnData,
                (uint256, uint256, uint256)
            );
            addPositionForUser(currentActor, positionId, receiptTokenId, actualAmount);

            _after(); //Checking after after createPosition

            invariant_YDT_01(positionId);
            invariant_YDT_02(params, actualAmount);
            invariant_YDT_03(positionId);
            invariant_YDT_04(params);
            // Success invariants
            onSuccessInvariantsGeneral(returnData);
        } else {
            // Failure invariants
            onFailInvariantsGeneral(returnData);
        }
    }

    // Postconditions for deposit
    function depositPostconditions(
        bool success,
        bytes memory returnData,
        YDF_DepositParams memory params
    ) internal {
        if (success) {
            // Decode return values
            (uint256 receiptTokenId, uint256 actualAmount) = abi.decode(
                returnData,
                (uint256, uint256)
            );

            _after();

            // Success invariants
            onSuccessInvariantsGeneral(returnData);
        } else {
            // Failure invariants
            onFailInvariantsGeneral(returnData);
        }
    }

    // Postconditions for claimYield
    function claimYieldPostconditions(
        bool success,
        bytes memory returnData,
        YDF_ClaimYieldParams memory params
    ) internal {
        if (success) {
            // Decode return value
            uint256 yieldMinusFee = abi.decode(returnData, (uint256));
            _after();

            invariant_YDT_05(params, yieldMinusFee);
            invariant_YDT_06(params);
            // Success invariants
            onSuccessInvariantsGeneral(returnData);
        } else {
            // Failure invariants
            onFailInvariantsGeneral(returnData);
        }
    }

    // Postconditions for setYieldFee
    function setYieldFeePostconditions(
        bool success,
        bytes memory returnData,
        YDF_SetYieldFeeParams memory params
    ) internal {
        _after();

        if (success) {
            onSuccessInvariantsGeneral(returnData);
        } else {
            onFailInvariantsGeneral(returnData);
        }
    }

    // Postconditions for simulateYield
    function simulateYieldPostconditions(
        bool success,
        bytes memory returnData,
        YDF_SimulateYieldParams memory params
    ) internal {
        _after();

        if (success) {
            onSuccessInvariantsGeneral(returnData);
        } else {
            onFailInvariantsGeneral(returnData);
        }
    }
}
