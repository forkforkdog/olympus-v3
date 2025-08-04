// SPDX-License-Identifier: UNTITLED
pragma solidity ^0.8.0;

import "./utils/FunctionCalls.sol";
import {IConvertibleDepositAuctioneer} from "src/policies/interfaces/deposits/IConvertibleDepositAuctioneer.sol";
import {DepositRedemptionVault} from "src/policies/deposits/DepositRedemptionVault.sol";

contract FuzzSetup is FunctionCalls {
    function fuzzSetup(bool echidnaEnabled) internal {
        // checkNonces(address(this));
        // checkNonces(address(0xf5e4fFeB7d2183B61753AA4074d72E51873C1D0a));
        // checkNonces(address(0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496));
        // assert(false);
        setUpBase(echidnaEnabled);

        deploySampleContract();
        setUpUsers();
        labelAll();
    }

    function checkNonces(address addr) internal {
        console.log("address", addr);
        for (uint256 i = 0; i < 10; i++) {
            console.log("nonce", i);
            console.log(_getCreateAddress(address(addr), i));
        }
    }

    function setUpBase(bool echidnaEnabled) internal {
        /// ===============================
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
        _createStack(echidnaEnabled);
    }

    function _createStack(bool echidnaEnabled) internal {
        kernel = new Kernel();

        treasury = new OlympusTreasury(kernel);
        minter = new OlympusMinter(kernel, address(ohm));
        roles = new OlympusRoles(kernel);
        // positionTokenRenderer = new PositionTokenRenderer();

        convertibleDepositPositions = new OlympusDepositPositionManager(
            address(kernel),
            address(0) //renderer not used
        );
        depositManager = new DepositManager(address(kernel));
        redemptionVault = new DepositRedemptionVault(address(kernel), address(depositManager));

        console.log("redeptionVault", address(redemptionVault));

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

        address priceAddr;

        if (echidnaEnabled) {
            priceAddr = deployContract(
                "src/test/mocks/MockPrice.sol:MockPrice",
                abi.encode(kernel, uint48(8 hours), 10 * 1e18)
            );
            console.log("priceAddr", priceAddr);
        } else {
            priceAddr = deployCode(
                "src/test/mocks/MockPrice.sol:MockPrice",
                abi.encode(kernel, uint48(8 hours), 10 * 1e18)
            );
            console.log("priceAddr", priceAddr);
        }

        kernel.executeAction(Actions.InstallModule, address(priceAddr));
        // PRICE = MockPrice(priceAddr);

        // Deploy clearinghouse registry with mock clearinghouse
        address clearinghouseAddr;
        if (echidnaEnabled) {
            clearinghouseAddr = deployContract(
                "MockClearinghouse.sol:MockClearinghouse",
                abi.encode(address(reserveToken), address(vault)) //TODO: clearing for second asset?
            );
        } else {
            clearinghouseAddr = deployCode(
                "MockClearinghouse.sol:MockClearinghouse",
                abi.encode(address(reserveToken), address(vault)) //TODO: clearing for second asset?
            );
        }

        // MockClearinghouse clearinghouse = MockClearinghouse(clearinghouseAddr);
        address chregAddr;
        if (echidnaEnabled) {
            chregAddr = deployContract(
                "OlympusClearinghouseRegistry.sol:OlympusClearinghouseRegistry",
                abi.encode(kernel, address(clearinghouseAddr), new address[](0))
            );
        } else {
            chregAddr = deployCode(
                "OlympusClearinghouseRegistry.sol:OlympusClearinghouseRegistry",
                abi.encode(kernel, address(clearinghouseAddr), new address[](0))
            );
        }
        kernel.executeAction(Actions.InstallModule, address(chregAddr));

        // CHREG = OlympusClearinghouseRegistry(chregAddr);

        // Deploy distributor (using ZeroDistributor)
        address stakingAddr;
        if (echidnaEnabled) {
            stakingAddr = deployContract(
                "src/test/mocks/MockStakingForZD.sol:MockStakingZD",
                abi.encode(8 hours, 0, block.timestamp)
            );
        } else {
            stakingAddr = deployCode(
                "src/test/mocks/MockStakingForZD.sol:MockStakingZD",
                abi.encode(8 hours, 0, block.timestamp)
            );
            stakingAddr = deployContract(
                "src/test/mocks/MockStakingForZD.sol:MockStakingZD",
                abi.encode(8 hours, 0, block.timestamp)
            );
        }
        // MockStakingZD staking = MockStakingZD(stakingAddr);
        address distributorAddr;
        if (echidnaEnabled) {
            distributorAddr = deployContract(
                "ZeroDistributor.sol:ZeroDistributor",
                abi.encode(address(stakingAddr))
            );
        } else {
            distributorAddr = deployCode(
                "ZeroDistributor.sol:ZeroDistributor",
                abi.encode(address(stakingAddr))
            );
        }
        // distributor = ZeroDistributor(distributorAddr);
        IStaking(stakingAddr).setDistributor(address(distributorAddr)); //TODO: uncomment this

        // // Deploy ReserveWrapper
        reserveWrapper = new ReserveWrapper(address(kernel), address(reserveToken), address(vault));

        // Deploy Bond system components for EmissionManager
        address guardian = address(this);
        RolesAuthority auth = new RolesAuthority(guardian, SolmateAuthority(address(0)));

        address aggregatorAddr;
        if (echidnaEnabled) {
            aggregatorAddr = deployContract(
                "BondAggregator.sol:BondAggregator",
                abi.encode(guardian, auth)
            );
        } else {
            aggregatorAddr = deployCode(
                "BondAggregator.sol:BondAggregator",
                abi.encode(guardian, auth)
            );
        }
        IBondAggregator aggregator = IBondAggregator(aggregatorAddr);

        address tellerAddr;
        if (echidnaEnabled) {
            tellerAddr = deployContract(
                "BondFixedTermTeller.sol:BondFixedTermTeller",
                abi.encode(guardian, aggregator, guardian, auth)
            );
        } else {
            tellerAddr = deployCode(
                "BondFixedTermTeller.sol:BondFixedTermTeller",
                abi.encode(guardian, aggregator, guardian, auth)
            );
        }
        IBondTeller teller = IBondTeller(tellerAddr);

        address bondAuctioneerAddr;
        if (echidnaEnabled) {
            bondAuctioneerAddr = deployContract(
                "BondFixedTermSDA.sol:BondFixedTermSDA",
                abi.encode(teller, aggregator, guardian, auth)
            );
        } else {
            bondAuctioneerAddr = deployCode(
                "BondFixedTermSDA.sol:BondFixedTermSDA",
                abi.encode(teller, aggregator, guardian, auth)
            );
        }

        IBondSDA bondAuctioneer = IBondSDA(bondAuctioneerAddr);

        aggregator.registerAuctioneer(bondAuctioneer);

        bytes memory constructorArgsEmissionManager = abi.encode(
            kernel,
            address(ohm),
            address(gohm),
            address(reserveToken),
            address(vault),
            address(bondAuctioneer),
            address(auctioneer),
            address(teller)
        );

        address emissionManagerDeployment;
        if (echidnaEnabled) {
            emissionManagerDeployment = deployContract(
                "EmissionManager.sol:EmissionManager",
                constructorArgsEmissionManager
            );
        } else {
            emissionManagerDeployment = deployCode(
                "EmissionManager.sol:EmissionManager",
                constructorArgsEmissionManager
            );
        }
        emissionManager = IEmissionManager(emissionManagerDeployment);

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
        kernel.executeAction(Actions.ActivatePolicy, address(emissionManager));
        kernel.executeAction(Actions.ActivatePolicy, address(redemptionVault));

        // // Grant roles
        rolesAdmin.grantRole(bytes32("cd_auctioneer"), address(auctioneer));
        rolesAdmin.grantRole(bytes32("emergency"), emergency);
        rolesAdmin.grantRole(bytes32("admin"), admin);
        rolesAdmin.grantRole(bytes32("deposit_operator"), address(convertibleDepositFacility));
        rolesAdmin.grantRole(bytes32("deposit_operator"), address(yieldDepositFacility));
        rolesAdmin.grantRole(bytes32("deposit_operator"), address(redemptionVault));

        // rolesAdmin.grantRole(bytes32("deposit_operator"), address(yieldDepositFacility));
        rolesAdmin.grantRole(bytes32("heart"), HEART);

        // Grant roles for new contracts
        rolesAdmin.grantRole(bytes32("heart_admin"), admin);
        rolesAdmin.grantRole(bytes32("manager"), admin);
        rolesAdmin.grantRole(bytes32("cd_emissionmanager"), HEART);
        rolesAdmin.grantRole(bytes32("emissions_admin"), admin);

        // Enable the deposit manager
        vm.prank(admin);
        depositManager.enable("");

        // Enable the convertibleDepositFacility
        vm.prank(admin);
        convertibleDepositFacility.enable("");

        // USING DIRECT CALL
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

        // Enable the redemption vault
        vm.prank(admin);
        redemptionVault.enable("");

        // Configure redemption vault borrowing parameters
        vm.startPrank(admin);
        redemptionVault.setMaxBorrowPercentage(IERC20(address(reserveToken)), 80e2); // 80%
        redemptionVault.setAnnualInterestRate(IERC20(address(reserveToken)), 5e2); // 5%
        redemptionVault.setMaxBorrowPercentage(IERC20(address(reserveTokenTwo)), 80e2); // 80%
        redemptionVault.setAnnualInterestRate(IERC20(address(reserveTokenTwo)), 5e2); // 5%
        redemptionVault.setClaimDefaultRewardPercentage(5e2); // 5% keeper reward
        vm.stopPrank();

        // Authorize facilities for redemption vault
        vm.prank(admin);
        redemptionVault.authorizeFacility(address(convertibleDepositFacility));
        vm.prank(admin);
        redemptionVault.authorizeFacility(address(yieldDepositFacility));

        vm.prank(admin);
        convertibleDepositFacility.authorizeOperator(address(redemptionVault));
        vm.prank(admin);
        yieldDepositFacility.authorizeOperator(address(redemptionVault));

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
            depositManager.approve(address(redemptionVault), receiptTokenId, type(uint256).max);

            // address wrappedToken = depositManager.getWrappedToken(receiptTokenId);
            // IERC20(wrappedToken).approve(address(depositManager), type(uint256).max);

            receiptTokenId = depositManager.getReceiptTokenId(
                IERC20(address(reserveTokenTwo)),
                PERIOD_MONTHS
            );
            depositManager.approve(address(depositManager), receiptTokenId, type(uint256).max);
            depositManager.approve(address(redemptionVault), receiptTokenId, type(uint256).max);

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
        // //KERNEL
        // vm.label(address(kernel), "KERNEL");
        // //TREASURY
        // vm.label(address(treasury), "TREASURY");
        // //MINTER
        // vm.label(address(minter), "MINTER");
        // //ROLES
        // vm.label(address(roles), "ROLES");
        // //POSITION TOKEN RENDERER
        // // vm.label(address(positionTokenRenderer), "POSITION TOKEN RENDERER");
        // //DEPOSIT MANAGER
        // vm.label(address(depositManager), "DEPOSIT MANAGER");
        // //CONVERTIBLE DEPOSIT FACILITY
        // vm.label(address(convertibleDepositFacility), "CONVERTIBLE DEPOSIT FACILITY");
        // //YIELD DEPOSIT FACILITY
        // vm.label(address(yieldDepositFacility), "YIELD DEPOSIT FACILITY");
        // //CONVERTIBLE DEPOSIT AUCTIONEER
        // vm.label(address(auctioneer), "CONVERTIBLE DEPOSIT AUCTIONEER");
        // //RESERVE WRAPPER
        // vm.label(address(reserveWrapper), "RESERVE WRAPPER");
        // //VAULT
        // vm.label(address(vault), "VAULT");
        // vm.label(address(vaultTwo), "VAULT TWO");
        // //ROLES ADMIN
        // vm.label(address(rolesAdmin), "ROLES ADMIN");
        // //SAMPLE CONTRACT
        // vm.label(address(sampleContract), "SAMPLE CONTRACT");
        // //GOHM
        // //CONTRACTS
        // vm.label(address(reserveToken), "RES");
        // vm.label(address(vault), "sRES");
        // vm.label(address(reserveTokenTwo), "RES2");
        // vm.label(address(vaultTwo), "sRES2");
        // //USERS
        // vm.label(USER1, "USER1");
        // vm.label(USER2, "USER2");
        // vm.label(USER3, "USER3");
    }

    function deployContract(
        string memory what,
        bytes memory args
    ) internal virtual returns (address addr) {
        bytes memory bytecode = abi.encodePacked(getCodeFFI(what), args);
        /// @solidity memory-safe-assembly
        assembly {
            addr := create(0, add(bytecode, 0x20), mload(bytecode))
        }

        require(addr != address(0), "StdCheats deployCode(string,bytes): Deployment failed.");
    }

    // function deployContractByType(type contractType, bytes memory args) internal returns (address addr) {
    //     bytes memory bytecode = abi.encodePacked(contractType.creationCode, args);
    //     /// @solidity memory-safe-assembly
    //     assembly {
    //         addr := create(0, add(bytecode, 0x20), mload(bytecode))
    //     }

    //     require(addr != address(0), "StdCheats deployCode(string,bytes): Deployment failed.");
    // }

    function getCodeFFI(string memory contractPath) internal returns (bytes memory) {
        string[] memory inputs = new string[](3);
        inputs[0] = "sh";
        inputs[1] = "-c";
        inputs[2] = string(
            abi.encodePacked("forge inspect ", contractPath, " bytecode | tr -d '\\n'")
        );

        return vm.ffi(inputs);
    }

    function increaseNonce(uint256 loops) internal {
        for (uint256 i = 0; i < loops; i++) {
            bytes
                memory code = hex"6080604052348015600f57600080fd5b50603f80601d6000396000f3fe6080604052600080fdfea2646970667358221220d1cd6a822e0e8a1a822f3e9e4a6b3c2c1c1d7bc9a3d3e7c99e7a61921d3b811064736f6c63430008130033";
            address deployedAddress;
            assembly {
                deployedAddress := create(0, add(code, 0x20), mload(code))
            }
        }
    }

    // calculates address of contract predeployment
    function _getCreateAddress(address deployer, uint256 nonce) internal pure returns (address) {
        if (nonce == 0) {
            return
                address(
                    uint160(
                        uint256(
                            keccak256(
                                abi.encodePacked(bytes1(0xd6), bytes1(0x94), deployer, bytes1(0x80))
                            )
                        )
                    )
                );
        } else if (nonce <= 0x7f) {
            return
                address(
                    uint160(
                        uint256(
                            keccak256(
                                abi.encodePacked(bytes1(0xd6), bytes1(0x94), deployer, uint8(nonce))
                            )
                        )
                    )
                );
        } else if (nonce <= 0xff) {
            return
                address(
                    uint160(
                        uint256(
                            keccak256(
                                abi.encodePacked(
                                    bytes1(0xd7),
                                    bytes1(0x94),
                                    deployer,
                                    bytes1(0x81),
                                    uint8(nonce)
                                )
                            )
                        )
                    )
                );
        } else if (nonce <= 0xffff) {
            return
                address(
                    uint160(
                        uint256(
                            keccak256(
                                abi.encodePacked(
                                    bytes1(0xd8),
                                    bytes1(0x94),
                                    deployer,
                                    bytes1(0x82),
                                    uint16(nonce)
                                )
                            )
                        )
                    )
                );
        } else {
            return
                address(
                    uint160(
                        uint256(
                            keccak256(
                                abi.encodePacked(
                                    bytes1(0xd9),
                                    bytes1(0x94),
                                    deployer,
                                    bytes1(0x83),
                                    uint24(nonce)
                                )
                            )
                        )
                    )
                );
        }
    }
}
