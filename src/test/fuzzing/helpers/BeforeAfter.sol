pragma solidity >=0.8.0;

import "../FuzzSetup.sol";
import "./FuzzStructs.sol";

contract BeforeAfter is FuzzStructs, FuzzSetup {
    mapping(uint8 => State) states;

    struct State {
        mapping(address => ActorStates) actorStates;
        uint256 contractEthBalance;
        mapping(uint256 => uint256) positionLastYieldConversionRate;
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
        // for (uint256 i = 0; i < positionIds.length; i++) {
        //     states[callNum].positionLastYieldConversionRate[positionIds[i]] = yieldDepositFacility
        //         .positionLastYieldConversionRate(positionIds[i]);
        //     states[callNum].isConvertible[positionIds[i]] = convertibleDepositPositions
        //         .isConvertible(positionIds[i]);
        // }

        // states[callNum].depositManagerBalance = reserveToken.balanceOf(address(depositManager));
        // states[callNum].depositManagerBalanceTwo = reserveTokenTwo.balanceOf(
        //     address(depositManager)
        // );
        // states[callNum].vaultBalance = reserveToken.balanceOf(address(vault));
        // states[callNum].vaultBalanceTwo = reserveTokenTwo.balanceOf(address(vaultTwo));

        // states[callNum].totalYieldAccrued = depositManager.maxClaimYield(
        //     reserveToken,
        //     address(yieldDepositFacility)
        // );
        // states[callNum].totalYieldAccruedTwo = depositManager.maxClaimYield(
        //     reserveTokenTwo,
        //     address(yieldDepositFacility)
        // );

        _logicalCoverage(callNum);
    }

    function _logicalCoverage(uint8 callNum) private {
        // Implement logical coverage here.
    }

    function _setActorState(uint8 callNum, address actor) internal virtual {
        // states[callNum].actorStates[actor].receiptTokenBalance = yieldDepositFacility.balanceOf(
        //     actor,
        //     receiptTokenId
        // );
        // states[callNum].actorStates[actor].receiptTokenBalanceTwo = yieldDepositFacility.balanceOf(
        //     actor,
        //     receiptTokenIdTwo
        // );
        // states[callNum].actorStates[actor].assetLiabilities = depositManager.getAssetLiabilities(
        //     address(reserveToken),
        //     actor
        // );
        // states[callNum].actorStates[actor].assetLiabilitiesTwo = depositManager.getAssetLiabilities(
        //     address(reserveTokenTwo),
        //     actor
        // );
        // states[callNum].actorStates[actor].totalPreviewClaimYield = 0;
        // for (uint256 i = 0; i < getUserPositions(actor).length; i++) {
        //     (uint256 previewYieldMinusFee, ) = yieldDepositFacility.previewClaimYield(
        //         actor,
        //         getUserPositions(actor)[i].positionId
        //     );
        //     states[callNum].actorStates[actor].totalPreviewClaimYield += previewYieldMinusFee;
        // }
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}
