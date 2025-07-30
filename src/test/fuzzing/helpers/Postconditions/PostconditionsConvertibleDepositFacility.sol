// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./PostconditionsBase.sol";
import "../BeforeAfter.sol";
import {IERC20} from "src/interfaces/IERC20.sol";
import {IConvertibleDepositFacility} from "src/policies/interfaces/deposits/IConvertibleDepositFacility.sol";

contract PostconditionsConvertibleDepositFacility is PostconditionsBase {
    function createPositionPostconditions(
        bool success,
        bytes memory returnData,
        CDF_CreatePositionParams memory params
    ) internal {
        _after();

        if (success) {
            (uint256 positionId, uint256 receiptTokenId, uint256 actualAmount) = abi.decode(
                returnData,
                (uint256, uint256, uint256)
            );
            addPositionForUser(currentActor, positionId, receiptTokenId, actualAmount);
            onSuccessInvariantsGeneral(returnData);
        } else {
            onFailInvariantsGeneral(returnData);
        }
    }

    function depositPostconditions(
        bool success,
        bytes memory returnData,
        CDF_DepositParams memory params
    ) internal {
        _after();

        if (success) {
            (uint256 receiptTokenId, uint256 actualAmount) = abi.decode(
                returnData,
                (uint256, uint256)
            );
            onSuccessInvariantsGeneral(returnData);
        } else {
            onFailInvariantsGeneral(returnData);
        }
    }

    function convertPostconditions(
        bool success,
        bytes memory returnData,
        CDF_ConvertParams memory params
    ) internal {
        _after();

        if (success) {
            (uint256 receiptTokenIn, uint256 convertedTokenOut) = abi.decode(
                returnData,
                (uint256, uint256)
            );
            onSuccessInvariantsGeneral(returnData);
        } else {
            onFailInvariantsGeneral(returnData);
        }
    }

    function claimYieldPostconditions(
        bool success,
        bytes memory returnData,
        CDF_ClaimYieldParams memory params
    ) internal {
        _after();

        if (success) {
            uint256 yieldAssets = abi.decode(returnData, (uint256));
            onSuccessInvariantsGeneral(returnData);
        } else {
            onFailInvariantsGeneral(returnData);
        }
    }

    function claimAllYieldPostconditions(bool success, bytes memory returnData) internal {
        _after();

        if (success) {
            onSuccessInvariantsGeneral(returnData);
        } else {
            onFailInvariantsGeneral(returnData);
        }
    }

    function executePostconditions(bool success, bytes memory returnData) internal {
        _after();

        if (success) {
            onSuccessInvariantsGeneral(returnData);
        } else {
            onFailInvariantsGeneral(returnData);
        }
    }

    function reclaimPostconditions(
        bool success,
        bytes memory returnData,
        CDF_ReclaimParams memory params
    ) internal {
        _after();

        if (success) {
            uint256 reclaimed = abi.decode(returnData, (uint256));
            onSuccessInvariantsGeneral(returnData);
        } else {
            onFailInvariantsGeneral(returnData);
        }
    }
}
