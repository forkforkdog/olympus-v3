// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./PreconditionsBase.sol";
import {IERC20} from "src/interfaces/IERC20.sol";
import {IDepositRedemptionVault} from "src/policies/interfaces/deposits/IDepositRedemptionVault.sol";
import {IDepositManager} from "src/policies/interfaces/deposits/IDepositManager.sol";

abstract contract PreconditionsDepositRedemptionVault is PreconditionsBase {
    // Start redemption preconditions
    function startRedemptionPreconditions(
        uint256 depositTokenSeed,
        uint8 depositPeriodSeed,
        uint256 amountSeed,
        uint256 facilitySeed
    ) internal returns (DRV_StartRedemptionParams memory params) {
        // Get configured assets from deposit manager
        IERC20[] memory assets = depositManager.getConfiguredAssets();
        require(assets.length > 0, "No assets configured");

        params.depositToken = assets[depositTokenSeed % assets.length];

        // Get valid periods for the asset
        IDepositManager.AssetPeriod[] memory periods = depositManager.getAssetPeriods();
        uint8[] memory validPeriods = new uint8[](periods.length);
        uint256 validCount = 0;

        for (uint256 i = 0; i < periods.length; i++) {
            if (address(periods[i].asset) == address(params.depositToken) && periods[i].isEnabled) {
                validPeriods[validCount] = periods[i].depositPeriod;
                validCount++;
            }
        }

        require(validCount > 0, "No valid periods for asset");
        params.depositPeriod = validPeriods[depositPeriodSeed % validCount];

        // Get receipt token balance
        uint256 receiptTokenId = depositManager.getReceiptTokenId(
            params.depositToken,
            params.depositPeriod
        );
        uint256 maxAmount = depositManager.balanceOf(currentActor, receiptTokenId);
        params.amount = fl.clamp(amountSeed, 1, maxAmount);

        // Get authorized facilities
        address[] memory facilities = redemptionVault.getAuthorizedFacilities();
        require(facilities.length > 0, "No authorized facilities");
        params.facility = facilities[facilitySeed % facilities.length];
    }

    // Cancel redemption preconditions
    function cancelRedemptionPreconditions(
        uint16 redemptionIdSeed,
        uint256 amountSeed
    ) internal returns (DRV_CancelRedemptionParams memory params) {
        uint16 redemptionCount = redemptionVault.getUserRedemptionCount(currentActor);
        require(redemptionCount > 0, "No redemptions for user");

        params.redemptionId = redemptionIdSeed % redemptionCount;

        // Get redemption details
        IDepositRedemptionVault.UserRedemption memory redemption = redemptionVault
            .getUserRedemption(currentActor, params.redemptionId);

        // Check if there's a loan - we can't cancel if there's an unpaid loan
        IDepositRedemptionVault.Loan memory loan = redemptionVault.getRedemptionLoan(
            currentActor,
            params.redemptionId
        );
        require(loan.principal == 0, "Cannot cancel redemption with unpaid loan");

        // Set amount between 1 and redemption amount
        params.amount = fl.clamp(amountSeed, 1, redemption.amount);
    }

    // Finish redemption preconditions
    function finishRedemptionPreconditions(
        uint16 redemptionIdSeed
    ) internal returns (DRV_FinishRedemptionParams memory params) {
        uint16 redemptionCount = redemptionVault.getUserRedemptionCount(currentActor);
        require(redemptionCount > 0, "No redemptions for user");

        params.redemptionId = redemptionIdSeed % redemptionCount;

        // Get redemption details to check if it's redeemable
        IDepositRedemptionVault.UserRedemption memory redemption = redemptionVault
            .getUserRedemption(currentActor, params.redemptionId);

        require(redemption.amount > 0, "Redemption already finished");
        require(block.timestamp >= redemption.redeemableAt, "Redemption not yet redeemable");

        // Check if there's a loan - we can't finish if there's an unpaid loan
        IDepositRedemptionVault.Loan memory loan = redemptionVault.getRedemptionLoan(
            currentActor,
            params.redemptionId
        );
        require(loan.principal == 0, "Cannot finish redemption with unpaid loan");
    }

    // Borrow against redemption preconditions
    function borrowAgainstRedemptionPreconditions(
        uint16 redemptionIdSeed
    ) internal returns (DRV_BorrowAgainstRedemptionParams memory params) {
        uint16 redemptionCount = redemptionVault.getUserRedemptionCount(currentActor);
        require(redemptionCount > 0, "No redemptions for user");

        params.redemptionId = redemptionIdSeed % redemptionCount;

        // Get redemption details
        IDepositRedemptionVault.UserRedemption memory redemption = redemptionVault
            .getUserRedemption(currentActor, params.redemptionId);

        require(redemption.amount > 0, "Redemption already finished");

        // Check if there's already a loan
        IDepositRedemptionVault.Loan memory loan = redemptionVault.getRedemptionLoan(
            currentActor,
            params.redemptionId
        );
        require(loan.dueDate == 0, "Already has a loan");

        // Check that max borrow percentage and interest rate are set
        uint16 maxBorrowPercentage = redemptionVault.getMaxBorrowPercentage(
            IERC20(redemption.depositToken)
        );

        require(maxBorrowPercentage > 0, "Max borrow percentage not set");

        uint16 interestRate = redemptionVault.getAnnualInterestRate(
            IERC20(redemption.depositToken)
        );
        require(interestRate > 0, "Interest rate not set");
    }

    // Repay loan preconditions
    function repayLoanPreconditions(
        uint16 redemptionIdSeed,
        uint256 amountSeed
    ) internal returns (DRV_RepayLoanParams memory params) {
        uint16 redemptionCount = redemptionVault.getUserRedemptionCount(currentActor);
        require(redemptionCount > 0, "No redemptions for user");

        params.redemptionId = redemptionIdSeed % redemptionCount;

        // Get loan details
        IDepositRedemptionVault.Loan memory loan = redemptionVault.getRedemptionLoan(
            currentActor,
            params.redemptionId
        );
        require(loan.dueDate != 0, "No loan exists");
        require(block.timestamp < loan.dueDate, "Loan is expired");
        require(!loan.isDefaulted, "Loan is defaulted");
        require(loan.principal > 0 || loan.interest > 0, "Loan already repaid");

        // Get redemption to find the deposit token
        IDepositRedemptionVault.UserRedemption memory redemption = redemptionVault
            .getUserRedemption(currentActor, params.redemptionId);

        // Set amount based on user's balance
        uint256 maxAmount = IERC20(redemption.depositToken).balanceOf(currentActor);
        uint256 totalDebt = loan.principal + loan.interest;
        params.amount = fl.clamp(amountSeed, 1, min(maxAmount, totalDebt));
    }

    // Extend loan preconditions
    function extendLoanPreconditions(
        uint16 redemptionIdSeed,
        uint8 monthsSeed
    ) internal returns (DRV_ExtendLoanParams memory params) {
        uint16 redemptionCount = redemptionVault.getUserRedemptionCount(currentActor);
        require(redemptionCount > 0, "No redemptions for user");

        params.redemptionId = redemptionIdSeed % redemptionCount;

        // Get loan details
        IDepositRedemptionVault.Loan memory loan = redemptionVault.getRedemptionLoan(
            currentActor,
            params.redemptionId
        );
        require(loan.dueDate != 0, "No loan exists");
        require(block.timestamp < loan.dueDate, "Loan is expired");
        require(!loan.isDefaulted, "Loan is defaulted");
        require(loan.principal > 0, "Loan already repaid");

        // Set months between 1 and 12
        params.months = uint8(fl.clamp(monthsSeed, 1, 12));

        // Get redemption to find the deposit token
        IDepositRedemptionVault.UserRedemption memory redemption = redemptionVault
            .getUserRedemption(currentActor, params.redemptionId);

        // Calculate interest payment needed
        (uint48 newDueDate, uint256 interestPayable) = redemptionVault.previewExtendLoan(
            currentActor,
            params.redemptionId,
            params.months
        );

        // Ensure user has enough balance to pay the interest
        uint256 userBalance = IERC20(redemption.depositToken).balanceOf(currentActor);
        require(userBalance >= interestPayable, "Insufficient balance for interest payment");
    }

    // Claim defaulted loan preconditions
    function claimDefaultedLoanPreconditions(
        uint256 userSeed,
        uint16 redemptionIdSeed
    ) internal returns (DRV_ClaimDefaultedLoanParams memory params) {
        // Select a user from the available users
        params.user = USERS[userSeed % USERS.length];

        uint16 redemptionCount = redemptionVault.getUserRedemptionCount(params.user);
        require(redemptionCount > 0, "No redemptions for user");

        params.redemptionId = redemptionIdSeed % redemptionCount;

        // Get loan details
        IDepositRedemptionVault.Loan memory loan = redemptionVault.getRedemptionLoan(
            params.user,
            params.redemptionId
        );
        require(loan.dueDate != 0, "No loan exists");
        require(block.timestamp >= loan.dueDate, "Loan not expired");
        require(!loan.isDefaulted, "Already defaulted");
        require(loan.principal > 0, "Loan already repaid");
    }
}
