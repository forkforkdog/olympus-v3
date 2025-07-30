// SPDX-License-Identifier: UNTITLED
pragma solidity ^0.8.0;

import "./utils/FunctionCalls.sol";
import {IConvertibleDepositAuctioneer} from "src/policies/interfaces/deposits/IConvertibleDepositAuctioneer.sol";

contract FuzzSetup is FunctionCalls {
    function fuzzSetup() internal {
        setUpBase();

        deploySampleContract();
        setUpUsers();
        labelAll();
    }

    function setUpBase() internal {
        ohm = new MockERC20("Olympus", "OHM", 9);
        reserveToken = new MockERC20("Reserve Token", "RES", 18);
        iReserveToken = IERC20(address(reserveToken));
        vault = new MockERC4626(reserveToken, "Vault", "VAULT");
        iVault = IERC4626(address(vault));

        reserveTokenTwo = new MockERC20("Reserve Token Two", "RES2", 18);
        iReserveTokenTwo = IERC20(address(reserveTokenTwo));
        vaultTwo = new MockERC4626(reserveTokenTwo, "Vault Two", "VAULT2");
        iVaultTwo = IERC4626(address(vaultTwo));

        // Instantiate bophades
        _createStack();
    }

    function _createStack() internal {
        kernel = new Kernel();
        treasury = new OlympusTreasury(kernel);
        minter = new OlympusMinter(kernel, address(ohm));
        roles = new OlympusRoles(kernel);
        positionTokenRenderer = new PositionTokenRenderer();

        convertibleDepositPositions = new OlympusDepositPositionManager(
            address(kernel),
            address(positionTokenRenderer)
        );
        depositManager = new DepositManager(address(kernel));
        redemptionVault = new DepositRedemptionVault(address(kernel), address(depositManager));

        convertibleDepositFacility = new ConvertibleDepositFacility(
            address(kernel),
            address(depositManager)
        );
        yieldDepositFacility = new YieldDepositFacility(address(kernel), address(depositManager));
        auctioneer = new ConvertibleDepositAuctioneer(
            address(kernel),
            address(convertibleDepositFacility),
            address(iReserveToken)
        );
        rolesAdmin = new RolesAdmin(kernel);

        // Deploy additional scope contracts
        // Deploy gOHM mock
        gohm = new MockGohm("Gohm", "gOHM", 18);

        // Deploy PRICE mock (with 8 hour frequency)
        // PRICE = new MockPrice(kernel, uint48(8 hours), 10 * 1e18);

        // // Deploy clearinghouse registry with mock clearinghouse
        // MockClearinghouse clearinghouse = new MockClearinghouse(
        //     address(reserveToken),
        //     address(vault)
        // );
        // CHREG = new OlympusClearinghouseRegistry(kernel, address(clearinghouse), new address[](0));

        // // Deploy distributor (using ZeroDistributor)
        // MockStakingZD staking = new MockStakingZD(8 hours, 0, block.timestamp);
        // distributor = new ZeroDistributor(address(staking));
        // staking.setDistributor(address(distributor));

        // // Deploy Heart
        // heart = new OlympusHeart(
        //     kernel,
        //     IDistributor(address(distributor)),
        //     uint256(10e9), // max reward = 10 reward tokens
        //     uint48(12 * 50) // auction duration = 5 minutes (50 blocks on ETH mainnet)
        // );

        // // Deploy ReserveWrapper
        reserveWrapper = new ReserveWrapper(address(kernel), address(reserveToken), address(vault));

        // Deploy Bond system components for EmissionManager
        // address guardian = address(this);
        // RolesAuthority auth = new RolesAuthority(guardian, SolmateAuthority(address(0)));
        // BondAggregator aggregator = new BondAggregator(guardian, auth);
        // BondFixedTermTeller teller = new BondFixedTermTeller(guardian, aggregator, guardian, auth);
        // BondFixedTermSDA bondAuctioneer = new BondFixedTermSDA(teller, aggregator, guardian, auth);

        // // Register bondAuctioneer
        // aggregator.registerAuctioneer(bondAuctioneer);

        // // Deploy mock CD auctioneer
        // MockConvertibleDepositAuctioneer cdAuctioneer = new MockConvertibleDepositAuctioneer(
        //     kernel,
        //     address(reserveToken)
        // );

        // // Deploy EmissionManager
        // emissionManager = new EmissionManager(
        //     kernel,
        //     address(ohm),
        //     address(gohm),
        //     address(reserveToken),
        //     address(vault),
        //     address(bondAuctioneer),
        //     address(cdAuctioneer),
        //     address(teller)
        // );

        // // Update convertibleDepositPositions to use the renderer
        // convertibleDepositPositions = new OlympusDepositPositionManager(
        //     address(kernel),
        //     address(positionTokenRenderer)
        // );

        // Install modules
        kernel.executeAction(Actions.InstallModule, address(treasury));
        kernel.executeAction(Actions.InstallModule, address(minter));
        kernel.executeAction(Actions.InstallModule, address(roles));
        kernel.executeAction(Actions.InstallModule, address(convertibleDepositPositions));
        // kernel.executeAction(Actions.InstallModule, address(PRICE));
        // kernel.executeAction(Actions.InstallModule, address(CHREG));

        kernel.executeAction(Actions.ActivatePolicy, address(depositManager));
        kernel.executeAction(Actions.ActivatePolicy, address(convertibleDepositFacility));
        kernel.executeAction(Actions.ActivatePolicy, address(yieldDepositFacility));
        kernel.executeAction(Actions.ActivatePolicy, address(rolesAdmin));
        kernel.executeAction(Actions.ActivatePolicy, address(auctioneer));
        // kernel.executeAction(Actions.ActivatePolicy, address(heart));
        kernel.executeAction(Actions.ActivatePolicy, address(reserveWrapper));
        // kernel.executeAction(Actions.ActivatePolicy, address(emissionManager));
        // kernel.executeAction(Actions.ActivatePolicy, address(cdAuctioneer));

        // // Grant roles
        rolesAdmin.grantRole(bytes32("cd_auctioneer"), address(auctioneer));
        rolesAdmin.grantRole(bytes32("emergency"), emergency);
        rolesAdmin.grantRole(bytes32("admin"), admin);
        rolesAdmin.grantRole(bytes32("deposit_operator"), address(convertibleDepositFacility));
        // rolesAdmin.grantRole(bytes32("deposit_operator"), address(yieldDepositFacility));
        // rolesAdmin.grantRole(bytes32("heart"), HEART);

        // Grant roles for new contracts
        rolesAdmin.grantRole(bytes32("heart_admin"), admin);
        rolesAdmin.grantRole(bytes32("manager"), admin);
        // rolesAdmin.grantRole(bytes32("cd_emissionmanager"), address(heart));
        rolesAdmin.grantRole(bytes32("emissions_admin"), admin);

        // Enable the deposit manager
        vm.prank(admin);
        depositManager.enable("");

        // Enable the convertibleDepositFacility
        vm.prank(admin);
        convertibleDepositFacility.enable("");

        // // Enable heart
        // vm.prank(admin);
        // heart.enable("");

        // // Enable reserve wrapper
        vm.prank(admin);
        reserveWrapper.enable("");

        // Create a receipt token
        vm.startPrank(admin);
        depositManager.addAsset(
            IERC20(address(reserveToken)),
            IERC4626(address(vault)),
            type(uint256).max
        );

        depositManager.addAssetPeriod(IERC20(address(reserveToken)), PERIOD_MONTHS, 90e2);

        receiptTokenId = depositManager.getReceiptTokenId(
            IERC20(address(reserveToken)),
            PERIOD_MONTHS
        );
        vm.stopPrank();

        // Create a second receipt token
        vm.startPrank(admin);
        depositManager.addAsset(
            IERC20(address(reserveTokenTwo)),
            IERC4626(address(vaultTwo)),
            type(uint256).max
        );

        depositManager.addAssetPeriod(IERC20(address(reserveTokenTwo)), PERIOD_MONTHS, 90e2);

        receiptTokenIdTwo = depositManager.getReceiptTokenId(
            IERC20(address(reserveTokenTwo)),
            PERIOD_MONTHS
        );
        vm.stopPrank();

        // Enable the yield deposit convertibleDepositFacility
        vm.prank(admin);
        yieldDepositFacility.enable("");

        vm.prank(admin);
        auctioneer.enableDepositPeriod(PERIOD_MONTHS);

        //TODO: use randomization handler
        vm.prank(admin);
        auctioneer.enable(
            abi.encode(
                IConvertibleDepositAuctioneer.EnableParams({
                    target: TARGET,
                    tickSize: TICK_SIZE,
                    minPrice: MIN_PRICE,
                    tickStep: TICK_STEP,
                    auctionTrackingPeriod: AUCTION_TRACKING_PERIOD
                })
            )
        );
        //    // Configure mocks
        //     PRICE.setMovingAverage(100 * 1e18);
        //     PRICE.setLastPrice(100 * 1e18);
        //     PRICE.setCurrentPrice(100 * 1e18);
        //     PRICE.setDecimals(18);
    }

    function setUpUsers() internal {
        for (uint256 i = 0; i < USERS.length; i++) {
            vm.startPrank(USERS[i]);
            reserveToken.approve(address(depositManager), type(uint256).max);
            reserveTokenTwo.approve(address(depositManager), type(uint256).max);
            reserveToken.approve(address(convertibleDepositFacility), type(uint256).max);
            reserveTokenTwo.approve(address(convertibleDepositFacility), type(uint256).max);
            reserveToken.approve(address(auctioneer), type(uint256).max);
            reserveTokenTwo.approve(address(auctioneer), type(uint256).max);
            reserveToken.approve(address(reserveWrapper), type(uint256).max);
            reserveTokenTwo.approve(address(reserveWrapper), type(uint256).max);
            reserveToken.approve(address(vault), type(uint256).max);
            reserveTokenTwo.approve(address(vault), type(uint256).max);
            reserveToken.approve(address(vaultTwo), type(uint256).max);
            reserveTokenTwo.approve(address(vaultTwo), type(uint256).max);

            uint256 receiptTokenId = depositManager.getReceiptTokenId(
                IERC20(address(reserveToken)),
                PERIOD_MONTHS
            );
            depositManager.approve(address(depositManager), receiptTokenId, type(uint256).max);

            // address wrappedToken = depositManager.getWrappedToken(receiptTokenId);
            // IERC20(wrappedToken).approve(address(depositManager), type(uint256).max);

            receiptTokenId = depositManager.getReceiptTokenId(
                IERC20(address(reserveTokenTwo)),
                PERIOD_MONTHS
            );
            depositManager.approve(address(depositManager), receiptTokenId, type(uint256).max);

            // wrappedToken = depositManager.getWrappedToken(receiptTokenId);
            // IERC20(wrappedToken).approve(address(depositManager), type(uint256).max);

            vm.stopPrank();
            reserveToken.mint(USERS[i], 1000_000_000_000e18);
            reserveTokenTwo.mint(USERS[i], 1000_000_000_000e18);
        }
    }

    function deploySampleContract() internal {
        sampleContract = new SampleContract();
    }

    //DO LABELING
    function labelAll() internal {
        //KERNEL
        vm.label(address(kernel), "KERNEL");

        //TREASURY
        vm.label(address(treasury), "TREASURY");

        //MINTER
        vm.label(address(minter), "MINTER");

        //ROLES
        vm.label(address(roles), "ROLES");

        //POSITION TOKEN RENDERER
        vm.label(address(positionTokenRenderer), "POSITION TOKEN RENDERER");

        //DEPOSIT MANAGER
        vm.label(address(depositManager), "DEPOSIT MANAGER");

        //CONVERTIBLE DEPOSIT FACILITY
        vm.label(address(convertibleDepositFacility), "CONVERTIBLE DEPOSIT FACILITY");

        //YIELD DEPOSIT FACILITY
        vm.label(address(yieldDepositFacility), "YIELD DEPOSIT FACILITY");

        //CONVERTIBLE DEPOSIT AUCTIONEER
        vm.label(address(auctioneer), "CONVERTIBLE DEPOSIT AUCTIONEER");

        //RESERVE WRAPPER
        vm.label(address(reserveWrapper), "RESERVE WRAPPER");

        //VAULT
        vm.label(address(vault), "VAULT");
        vm.label(address(vaultTwo), "VAULT TWO");

        //ROLES ADMIN
        vm.label(address(rolesAdmin), "ROLES ADMIN");

        //SAMPLE CONTRACT
        vm.label(address(sampleContract), "SAMPLE CONTRACT");

        //GOHM
        //CONTRACTS
        vm.label(address(reserveToken), "RES");
        vm.label(address(vault), "sRES");
        vm.label(address(reserveTokenTwo), "RES2");
        vm.label(address(vaultTwo), "sRES2");
        //USERS
        vm.label(USER1, "USER1");
        vm.label(USER2, "USER2");
        vm.label(USER3, "USER3");
    }
}
