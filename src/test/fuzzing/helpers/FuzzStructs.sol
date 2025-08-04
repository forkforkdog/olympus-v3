pragma solidity >=0.8.0;

import {IERC20} from "src/interfaces/IERC20.sol";

contract FuzzStructs {
    // ConvertibleDepositAuctioneer structs
    struct BidParams {
        uint8 depositPeriod;
        uint256 depositAmount;
        bool wrapPosition;
        bool wrapReceipt;
    }

    struct EnableDepositPeriodParams {
        uint8 depositPeriod;
    }

    struct DisableDepositPeriodParams {
        uint8 depositPeriod;
    }

    struct SetAuctionParametersParams {
        uint256 target;
        uint256 tickSize;
        uint256 minPrice;
    }

    struct SetTickStepParams {
        uint24 newStep;
    }

    struct SetAuctionTrackingPeriodParams {
        uint8 daysNumber;
    }

    // ========== ConvertibleDepositFacility structs ==========
    struct CDF_CreatePositionParams {
        IERC20 asset;
        uint8 periodMonths;
        address depositor;
        uint256 amount;
        uint256 conversionPrice;
        bool wrapPosition;
        bool wrapReceipt;
    }

    struct CDF_DepositParams {
        IERC20 asset;
        uint8 periodMonths;
        uint256 amount;
        bool wrapReceipt;
    }

    struct CDF_ConvertParams {
        uint256[] positionIds;
        uint256[] amounts;
        bool wrappedReceipt;
    }

    struct CDF_ClaimYieldParams {
        IERC20 asset;
    }

    struct CDF_ReclaimParams {
        IERC20 asset;
        uint8 periodMonths;
        uint256 amount;
    }

    // ========== YieldDepositFacility structs ==========
    struct YDF_CreatePositionParams {
        IERC20 asset;
        uint8 periodMonths;
        uint256 amount;
        bool wrapReceipt;
        bool wrapPosition;
    }

    struct YDF_DepositParams {
        IERC20 asset;
        uint8 periodMonths;
        uint256 amount;
        bool wrapReceipt;
    }

    struct YDF_ClaimYieldParams {
        uint256[] positionIds;
        uint48[] timestampHints;
    }

    struct YDF_SetYieldFeeParams {
        uint16 yieldFee;
    }

    // Struct definitions for parameters
    struct DRV_StartRedemptionParams {
        IERC20 depositToken;
        uint8 depositPeriod;
        uint256 amount;
        address facility;
    }

    struct DRV_CancelRedemptionParams {
        uint16 redemptionId;
        uint256 amount;
    }

    struct DRV_FinishRedemptionParams {
        uint16 redemptionId;
    }

    struct DRV_BorrowAgainstRedemptionParams {
        uint16 redemptionId;
    }

    struct DRV_RepayLoanParams {
        uint16 redemptionId;
        uint256 amount;
    }

    struct DRV_ExtendLoanParams {
        uint16 redemptionId;
        uint8 months;
    }

    struct DRV_ClaimDefaultedLoanParams {
        address user;
        uint16 redemptionId;
    }

    /// Sample contract structs

    struct SampleFunctionParams {
        uint256 sampleUint;
    }

    struct SampleFailWithRequireParams {
        bool sampleUint;
    }

    struct SampleFailWithCustomErrorParams {
        uint8 sampleUint;
    }

    struct SampleFailWithPanicParams {
        uint256 sampleUint;
    }

    struct SampleFailWithAssertParams {
        uint256 sampleUint;
    }

    struct SampleFailReturnEmptyDataParams {
        bool sampleUint;
    }
}
