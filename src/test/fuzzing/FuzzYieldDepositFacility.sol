// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./helpers/Preconditions/PreconditionsYieldDepositFacility.sol";
import "./helpers/Postconditions/PostconditionsYieldDepositFacility.sol";
import {IERC20} from "src/interfaces/IERC20.sol";
import {IERC4626} from "src/interfaces/IERC4626.sol";
import {IYieldDepositFacility} from "src/policies/interfaces/deposits/IYieldDepositFacility.sol";
import {YieldDepositFacility} from "src/policies/deposits/YieldDepositFacility.sol";
import "forge-std/console.sol";

contract FuzzYieldDepositFacility is
    PreconditionsYieldDepositFacility,
    PostconditionsYieldDepositFacility
{
    function fuzz_YDF_createPosition(
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

    // Time tracking for 8-hour execution intervals
    uint256 public lastExecuteTimestamp;
    uint48 private constant EXECUTE_INTERVAL = 8 hours;

    function fuzz_YDF_execute() public setCurrentActor {
        _before();

        // Calculate and apply time warp for 8-hour interval
        _warpToNextExecuteWindow();

        fl.doFunctionCall(
            address(HEART),
            abi.encodeWithSelector(YieldDepositFacility.execute.selector)
        );

        // Update the last execute timestamp
        lastExecuteTimestamp = block.timestamp;

        _after();
    }

    /// @notice Warps time to ensure execute is called every 8 hours
    /// @dev This function calculates the appropriate time to warp to maintain 8-hour intervals
    function _warpToNextExecuteWindow() internal {
        uint256 currentTime = block.timestamp;

        // If this is the first call, initialize with current time
        if (lastExecuteTimestamp == 0) {
            lastExecuteTimestamp = currentTime;
            return;
        }

        // Calculate time since last execute
        uint256 timeSinceLastExecute = currentTime - lastExecuteTimestamp;

        // If less than 8 hours have passed, warp to complete the 8-hour interval
        if (timeSinceLastExecute < EXECUTE_INTERVAL) {
            uint256 timeToWarp = EXECUTE_INTERVAL - timeSinceLastExecute;
            vm.warp(currentTime + timeToWarp);

            console.log("Warped time by", timeToWarp, "seconds to complete 8-hour interval");
            console.log("New block timestamp:", block.timestamp);
        }
        // If more than 8 hours have passed, warp to the next 8-hour boundary
        else if (timeSinceLastExecute > EXECUTE_INTERVAL) {
            // Calculate how many complete 8-hour intervals have passed
            uint256 intervalsPassed = timeSinceLastExecute / EXECUTE_INTERVAL;

            // Warp to the next 8-hour boundary after the last complete interval
            uint256 nextExecuteTime = lastExecuteTimestamp +
                ((intervalsPassed + 1) * EXECUTE_INTERVAL);
            vm.warp(nextExecuteTime);

            console.log("Warped to next 8-hour boundary at timestamp:", nextExecuteTime);
            console.log("Intervals passed since last execute:", intervalsPassed);
        }
        // If exactly 8 hours have passed, no warp needed
        else {
            console.log("Exactly 8 hours have passed, no warp needed");
        }
    }

    /// @notice Simulates yield generation by minting or burning tokens in vaults
    /// @dev This randomly mints or burns reserve tokens to/from vaults to change conversion rates
    /// @param actionSeed Seed to determine mint/burn and amount
    /// @param assetSeed Seed to determine which asset (reserve token 1 or 2)
    function fuzz_YDF_simulateYield(uint256 actionSeed, uint256 assetSeed) public {
        YDF_SimulateYieldParams memory params = simulateYieldPreconditions(actionSeed, assetSeed);

        if (params.amount == 0) {
            return;
        }

        _before();

        bool success = true;
        bytes memory returnData;

        if (params.shouldMint) {
            // Mint tokens directly to vault to simulate yield
            bool useVaultOne = params.targetVault == address(vault);
            if (useVaultOne) {
                reserveToken.mint(params.targetVault, params.amount);
            } else {
                reserveTokenTwo.mint(params.targetVault, params.amount);
            }
        } else {
            // Burn tokens from vault to simulate loss
            uint256 currentBalance = params.targetAsset.balanceOf(params.targetVault);
            if (params.amount <= currentBalance) {
                bool useVaultOne = params.targetVault == address(vault);
                if (useVaultOne) {
                    reserveToken.burn(params.targetVault, params.amount);
                } else {
                    reserveTokenTwo.burn(params.targetVault, params.amount);
                }
            } else {
                success = false;
            }
        }

        // Log the new conversion rate for debugging
        uint256 newRate = IERC4626(params.targetVault).convertToAssets(
            10 ** IERC4626(params.targetVault).decimals()
        );
        console.log("New conversion rate for vault:", newRate);

        returnData = abi.encode(newRate);

        simulateYieldPostconditions(success, returnData, params);
    }
}
