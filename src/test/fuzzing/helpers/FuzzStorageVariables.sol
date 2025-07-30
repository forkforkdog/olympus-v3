// SPDX-License-Identifier: UNTITLED
pragma solidity >=0.8.0;

import "../SampleContract.sol";

import "../utils/FuzzActors.sol";
import {MockERC20} from "@solmate-6.2.0/test/utils/mocks/MockERC20.sol";
import {MockERC4626} from "@solmate-6.2.0/test/utils/mocks/MockERC4626.sol";

import {IERC20} from "src/interfaces/IERC20.sol";
import {IERC4626} from "src/interfaces/IERC4626.sol";
import {IBondSDA} from "src/interfaces/IBondSDA.sol";
import {IBondTeller} from "src/interfaces/IBondTeller.sol";
import {IBondAggregator} from "src/interfaces/IBondAggregator.sol";

import {Kernel, Actions} from "src/Kernel.sol";
import {ConvertibleDepositFacility} from "src/policies/deposits/ConvertibleDepositFacility.sol";
import {YieldDepositFacility} from "src/policies/deposits/YieldDepositFacility.sol";
import {OlympusTreasury} from "src/modules/TRSRY/OlympusTreasury.sol";
import {OlympusMinter} from "src/modules/MINTR/OlympusMinter.sol";
import {OlympusRoles} from "src/modules/ROLES/OlympusRoles.sol";
import {OlympusDepositPositionManager} from "src/modules/DEPOS/OlympusDepositPositionManager.sol";
import {RolesAdmin} from "src/policies/RolesAdmin.sol";
import {ROLESv1} from "src/modules/ROLES/ROLES.v1.sol";
import {DepositManager} from "src/policies/deposits/DepositManager.sol";
import {IEnabler} from "src/periphery/interfaces/IEnabler.sol";
import {IDepositManager} from "src/policies/interfaces/deposits/IDepositManager.sol";
import {IDepositRedemptionVault} from "src/policies/interfaces/deposits/IDepositRedemptionVault.sol";
import {IConvertibleDepositFacility} from "src/policies/interfaces/deposits/IConvertibleDepositFacility.sol";
import {IYieldDepositFacility} from "src/policies/interfaces/deposits/IYieldDepositFacility.sol";
import {ERC6909} from "@openzeppelin-5.3.0/token/ERC6909/draft-ERC6909.sol";
import {IDepositFacility} from "src/policies/interfaces/deposits/IDepositFacility.sol";
import {IPolicyAdmin} from "src/policies/interfaces/utils/IPolicyAdmin.sol";
import {ConvertibleDepositAuctioneer} from "src/policies/deposits/ConvertibleDepositAuctioneer.sol";
import {DepositRedemptionVault} from "src/policies/deposits/DepositRedemptionVault.sol";

// import {OlympusHeart} from "src/policies/Heart.sol";
import {ReserveWrapper} from "src/policies/ReserveWrapper.sol";
// import {EmissionManager} from "src/policies/EmissionManager.sol";
import {PositionTokenRenderer} from "src/modules/DEPOS/PositionTokenRenderer.sol";
// import {IDistributor} from "src/policies/interfaces/IDistributor.sol";
// import {IStaking} from "src/interfaces/IStaking.sol";
// import {OlympusClearinghouseRegistry} from "src/modules/CHREG/OlympusClearinghouseRegistry.sol";
// import {MockPrice} from "src/test/mocks/MockPrice.sol";
// import {MockClearinghouse} from "src/test/mocks/MockClearinghouse.sol";
// import {MockConvertibleDepositAuctioneer} from "src/test/mocks/MockConvertibleDepositAuctioneer.sol";
import {MockGohm} from "src/test/mocks/MockGohm.sol";

// import {ZeroDistributor} from "src/policies/Distributor/ZeroDistributor.sol";
// import {MockStakingZD} from "src/test/mocks/MockStakingForZD.sol";

// // Bond system imports
// import {BondFixedTermSDA} from "src/test/lib/bonds/BondFixedTermSDA.sol";
// import {BondAggregator} from "src/test/lib/bonds/BondAggregator.sol";
// import {BondFixedTermTeller} from "src/test/lib/bonds/BondFixedTermTeller.sol";
// import {RolesAuthority, Authority as SolmateAuthority} from "@solmate-6.2.0/auth/authorities/RolesAuthority.sol";

contract FuzzStorageVariables is FuzzActors {
    // ==============================================================
    // FUZZING SUITE SETUP
    // ==============================================================

    address currentActor;
    bool _setActor = true;

    uint256 internal constant PRIME = 2147483647;
    uint256 internal constant SEED = 22;
    uint256 iteration = 1; // fuzzing iteration
    uint256 lastTimestamp;

    //==============================================================
    // REVERTS CONFIGURATION
    //==============================================================

    bool internal constant CATCH_REQUIRE_REVERT = true; // Set to false to ignore require()/revert()
    bool internal constant CATCH_EMPTY_REVERTS = true; // Set to true to allow empty return data

    // ==============================================================
    // CONTRACTS
    // ==============================================================
    Kernel public kernel;
    ConvertibleDepositFacility public convertibleDepositFacility;
    YieldDepositFacility public yieldDepositFacility;
    OlympusTreasury public treasury;
    OlympusMinter public minter;
    OlympusRoles public roles;
    OlympusDepositPositionManager public convertibleDepositPositions;
    RolesAdmin public rolesAdmin;
    DepositManager public depositManager;
    ConvertibleDepositAuctioneer public auctioneer;
    MockERC20 public ohm;
    MockERC20 public reserveToken;
    MockERC4626 public vault;
    IERC20 internal iReserveToken;
    IERC4626 internal iVault;
    uint256 public receiptTokenId;
    DepositRedemptionVault public redemptionVault;

    // OlympusHeart public heart;
    ReserveWrapper public reserveWrapper;
    // EmissionManager public emissionManager;
    PositionTokenRenderer public positionTokenRenderer;
    // MockPrice public PRICE;
    // // OlympusClearinghouseRegistry public CHREG;
    // IDistributor public distributor;
    MockGohm public gohm;

    MockERC20 public reserveTokenTwo;
    MockERC4626 public vaultTwo;
    IERC20 internal iReserveTokenTwo;
    IERC4626 internal iVaultTwo;
    uint256 public receiptTokenIdTwo;

    //TODO: randomization on setup
    uint48 public constant INITIAL_BLOCK = 1_000_000;
    uint256 public constant CONVERSION_PRICE = 2e18;
    uint256 public constant RESERVE_TOKEN_AMOUNT = 10e18;
    uint16 public constant RECLAIM_RATE = 90e2;
    uint8 public constant PERIOD_MONTHS = 6;
    uint48 public constant CONVERSION_EXPIRY = INITIAL_BLOCK + (30 days) * PERIOD_MONTHS;

    uint256 public constant TICK_SIZE = 10e9;
    uint24 public constant TICK_STEP = 110e2; // 110%
    uint256 public constant MIN_PRICE = 15e18;
    uint256 public constant TARGET = 20e9;
    uint8 public constant AUCTION_TRACKING_PERIOD = 7;

    uint256 previousDepositActual;
    uint256 previousBorrowActual;
    SampleContract internal sampleContract;

    struct Position {
        uint256 positionId;
        uint256 receiptTokenId;
        uint256 actualAmount;
    }

    mapping(address => Position[]) public positionsByUser;
    mapping(address => mapping(uint256 => uint256)) public userPositionIndex; // Maps user -> positionId -> array index

    // Helper functions for managing multiple positions per user
    function addPositionForUser(
        address user,
        uint256 positionId,
        uint256 receiptTokenId,
        uint256 actualAmount
    ) internal {
        Position memory newPosition = Position({
            positionId: positionId,
            receiptTokenId: receiptTokenId,
            actualAmount: actualAmount
        });

        uint256 index = positionsByUser[user].length;
        positionsByUser[user].push(newPosition);
        userPositionIndex[user][positionId] = index;
    }

    function removePositionForUser(address user, uint256 positionId) internal {
        uint256 index = userPositionIndex[user][positionId];
        uint256 lastIndex = positionsByUser[user].length - 1;

        if (index != lastIndex) {
            // Move the last position to the removed position's slot
            Position memory lastPosition = positionsByUser[user][lastIndex];
            positionsByUser[user][index] = lastPosition;
            userPositionIndex[user][lastPosition.positionId] = index;
        }

        positionsByUser[user].pop();
        delete userPositionIndex[user][positionId];
    }

    function getUserPositions(address user) internal returns (Position[] memory) {
        return positionsByUser[user];
    }

    function getUserPositionCount(address user) internal returns (uint256) {
        return positionsByUser[user].length;
    }

    function getPositionByUserAndId(
        address user,
        uint256 positionId
    ) internal returns (Position memory) {
        uint256 index = userPositionIndex[user][positionId];
        return positionsByUser[user][index];
    }
}
