// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./helpers/Preconditions/PreconditionsDepositRedemptionVault.sol";
import "./helpers/Postconditions/PostconditionsDepositRedemptionVault.sol";
import {IERC20} from "src/interfaces/IERC20.sol";
import {IDepositRedemptionVault} from "src/policies/interfaces/deposits/IDepositRedemptionVault.sol";

contract FuzzDepositRedemptionVault is
    PreconditionsDepositRedemptionVault,
    PostconditionsDepositRedemptionVault
{
    function fuzz_DRV_startRedemption(
        uint256 depositTokenSeed,
        uint8 depositPeriodSeed,
        uint256 amountSeed,
        uint256 facilitySeed
    ) public setCurrentActor {
        DRV_StartRedemptionParams memory params = startRedemptionPreconditions(
            depositTokenSeed,
            depositPeriodSeed,
            amountSeed,
            facilitySeed
        );

        _before();

        (bool success, bytes memory returnData) = fl.doFunctionCall(
            address(redemptionVault),
            abi.encodeWithSelector(
                IDepositRedemptionVault.startRedemption.selector,
                params.depositToken,
                params.depositPeriod,
                params.amount,
                params.facility
            ),
            currentActor
        );

        startRedemptionPostconditions(success, returnData, params);
    }

    function fuzz_DRV_cancelRedemption(
        uint16 redemptionIdSeed,
        uint256 amountSeed
    ) public setCurrentActor {
        DRV_CancelRedemptionParams memory params = cancelRedemptionPreconditions(
            redemptionIdSeed,
            amountSeed
        );

        _before();

        (bool success, bytes memory returnData) = fl.doFunctionCall(
            address(redemptionVault),
            abi.encodeWithSelector(
                IDepositRedemptionVault.cancelRedemption.selector,
                params.redemptionId,
                params.amount
            ),
            currentActor
        );

        cancelRedemptionPostconditions(success, returnData, params);
    }

    function fuzz_DRV_finishRedemption(uint16 redemptionIdSeed) public setCurrentActor {
        DRV_FinishRedemptionParams memory params = finishRedemptionPreconditions(redemptionIdSeed);

        _before();

        (bool success, bytes memory returnData) = fl.doFunctionCall(
            address(redemptionVault),
            abi.encodeWithSelector(
                IDepositRedemptionVault.finishRedemption.selector,
                params.redemptionId
            ),
            currentActor
        );

        finishRedemptionPostconditions(success, returnData, params);
    }

    function fuzz_DRV_borrowAgainstRedemption(uint16 redemptionIdSeed) public setCurrentActor {
        DRV_BorrowAgainstRedemptionParams memory params = borrowAgainstRedemptionPreconditions(
            redemptionIdSeed
        );

        _before();

        (bool success, bytes memory returnData) = fl.doFunctionCall(
            address(redemptionVault),
            abi.encodeWithSelector(
                IDepositRedemptionVault.borrowAgainstRedemption.selector,
                params.redemptionId
            ),
            currentActor
        );

        borrowAgainstRedemptionPostconditions(success, returnData, params);
    }

    function fuzz_DRV_repayLoan(
        uint16 redemptionIdSeed,
        uint256 amountSeed
    ) public setCurrentActor {
        DRV_RepayLoanParams memory params = repayLoanPreconditions(redemptionIdSeed, amountSeed);

        _before();

        (bool success, bytes memory returnData) = fl.doFunctionCall(
            address(redemptionVault),
            abi.encodeWithSelector(
                IDepositRedemptionVault.repayLoan.selector,
                params.redemptionId,
                params.amount
            ),
            currentActor
        );

        repayLoanPostconditions(success, returnData, params);
    }

    function fuzz_DRV_extendLoan(uint16 redemptionIdSeed, uint8 monthsSeed) public setCurrentActor {
        DRV_ExtendLoanParams memory params = extendLoanPreconditions(redemptionIdSeed, monthsSeed);

        _before();

        (bool success, bytes memory returnData) = fl.doFunctionCall(
            address(redemptionVault),
            abi.encodeWithSelector(
                IDepositRedemptionVault.extendLoan.selector,
                params.redemptionId,
                params.months
            ),
            currentActor
        );

        extendLoanPostconditions(success, returnData, params);
    }

    function fuzz_DRV_claimDefaultedLoan(
        uint256 userSeed,
        uint16 redemptionIdSeed
    ) public setCurrentActor {
        DRV_ClaimDefaultedLoanParams memory params = claimDefaultedLoanPreconditions(
            userSeed,
            redemptionIdSeed
        );

        _before();

        (bool success, bytes memory returnData) = fl.doFunctionCall(
            address(redemptionVault),
            abi.encodeWithSelector(
                IDepositRedemptionVault.claimDefaultedLoan.selector,
                params.user,
                params.redemptionId
            ),
            currentActor
        );

        claimDefaultedLoanPostconditions(success, returnData, params);
    }
}
