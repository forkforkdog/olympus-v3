pragma solidity >=0.8.0;

import "../FuzzSetup.sol";
import "./FuzzStructs.sol";

contract BeforeAfter is FuzzStructs, FuzzSetup {
    mapping(uint8 => State) states;

    struct State {
        mapping(address => ActorStates) actorStates;
        mapping(uint256 => uint256) positionLastYieldConversionRate;
        mapping(uint256 => bool) isConvertible;
        uint256 contractEthBalance;
        uint256 depositManagerBalance;
        uint256 depositManagerBalanceTwo;
        uint256 vaultBalance;
        uint256 vaultBalanceTwo;
        uint256 totalYieldAccrued;
        uint256 totalYieldAccruedTwo;
        uint256 trsryBalance;
        uint256 trsryBalanceTwo;
        uint256 YDT_assetLiabilitiesOne;
        uint256 YDT_assetLiabilitiesTwo;
        uint256 sumAllActorYieldPreviews;
        uint256 sumAllActorYieldPreviewsTwo;
    }

    struct ActorStates {
        uint256 assetLiabilities;
        uint256 assetLiabilitiesTwo;
        uint256 totalPreviewClaimYield;
        uint256 totalPreviewClaimYieldTwo;
        uint256 receiptTokenBalance;
        uint256 receiptTokenBalanceTwo;
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
        // Reset the sum before processing actors
        states[callNum].sumAllActorYieldPreviews = 0;
        states[callNum].sumAllActorYieldPreviewsTwo = 0;
        
        for (uint256 i = 0; i < actors.length; i++) {
            _setActorState(callNum, actors[i]);
        }
    }

    function _updateCommonState(uint8 callNum) private {
        for (uint256 i = 0; i < positionIds.length; i++) {
            states[callNum].positionLastYieldConversionRate[positionIds[i]] = yieldDepositFacility
                .positionLastYieldConversionRate(positionIds[i]);
            states[callNum].isConvertible[positionIds[i]] = convertibleDepositPositions
                .isConvertible(positionIds[i]);
        }

        states[callNum].depositManagerBalance = reserveToken.balanceOf(address(depositManager));
        states[callNum].depositManagerBalanceTwo = reserveTokenTwo.balanceOf(
            address(depositManager)
        );
        states[callNum].vaultBalance = reserveToken.balanceOf(address(vault));
        states[callNum].vaultBalanceTwo = reserveTokenTwo.balanceOf(address(vaultTwo));
        states[callNum].trsryBalance = reserveToken.balanceOf(address(treasury));
        states[callNum].trsryBalanceTwo = reserveTokenTwo.balanceOf(address(treasury));

        states[callNum].totalYieldAccrued = depositManager.maxClaimYield(
            IERC20(address(reserveToken)),
            address(yieldDepositFacility)
        );
        states[callNum].totalYieldAccruedTwo = depositManager.maxClaimYield(
            IERC20(address(reserveTokenTwo)),
            address(yieldDepositFacility)
        );
        states[callNum].YDT_assetLiabilitiesOne = depositManager.getAssetLiabilities(
            address(reserveToken),
            address(yieldDepositFacility)
        );
        states[callNum].YDT_assetLiabilitiesTwo = depositManager.getAssetLiabilities(
            address(reserveTokenTwo),
            address(yieldDepositFacility)
        );
        _logicalCoverage(callNum);
    }

    function _logicalCoverage(uint8 callNum) private {
        // Implement logical coverage here.
    }

    function _setActorState(uint8 callNum, address actor) internal virtual {
        // Only preview claim yield if the user has positions
        uint256[] memory userPositionIds = getUserPositionIds(actor);
        if (userPositionIds.length > 0) {
            (uint256 previewYieldMinusFee, ) = yieldDepositFacility.previewClaimYield(
                actor,
                userPositionIds
            );
            // Don't accumulate, just set the current preview value
            states[callNum].actorStates[actor].totalPreviewClaimYield = previewYieldMinusFee;
            // Add to the sum for this state
            states[callNum].sumAllActorYieldPreviews += previewYieldMinusFee;
        }
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}
