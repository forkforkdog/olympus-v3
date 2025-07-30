pragma solidity >=0.8.0;

import "../FuzzSetup.sol";

contract BeforeAfter is FuzzSetup {
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

    mapping(uint8 => State) states;

    struct State {
        mapping(address => ActorStates) actorStates;
        uint256 contractEthBalance;
    }

    struct ActorStates {
        uint256 userEthBalance;
    }

    function _before(address[] memory actors) internal {
        // Reset full state mapping
        // delete states[0]; //use only if needed
        // delete states[1]; //use only if needed
        _setStates(0, actors);
    }

    function _after(address[] memory actors) internal {
        _setStates(1, actors);
    }

    function _before() internal {
        _setStates(0, USERS);
    }

    function _after() internal {
        _setStates(1, USERS);
    }

    function _setStates(uint8 callNum, address[] memory actors) internal {
        _processActors(callNum, actors);
        _updateCommonState(callNum);
    }

    function _processActors(uint8 callNum, address[] memory actors) private {
        for (uint256 i = 0; i < actors.length; i++) {
            _setActorState(callNum, actors[i]);
        }
    }

    function _updateCommonState(uint8 callNum) private {
        _logicalCoverage(callNum);
    }

    function _logicalCoverage(uint8 callNum) private {
        // Implement logical coverage here.
    }

    function _setActorState(uint8 callNum, address actor) internal virtual {}

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}
