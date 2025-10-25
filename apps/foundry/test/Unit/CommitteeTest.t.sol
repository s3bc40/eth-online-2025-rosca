// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console, Vm} from "forge-std/Test.sol";
import {Committee} from "../../src/Committee.sol";
import {MockERC20} from "../Mocks/MockERC20.sol";
import {MockWETH} from "../Mocks/MockWeth.sol";
import {MockEntropy} from "../Mocks/MockEntropy.sol";
import {MockAutomationRegistrar, MockAutomationRegistry} from "../Mocks/MockAutomationRegistrarAndRegistry.sol";

/**
 * @title CommitteeTest
 * @notice Comprehensive unit tests for the Committee contract
 * @dev Tests ROSCA functionality, Chainlink Automation integration, and Pyth Entropy randomness
 */
contract CommitteeTest is Test {
    Committee public committee;

    // Mock contracts
    MockERC20 public pyUsd;
    MockERC20 public link;
    MockWETH public weth;
    MockEntropy public entropy;
    MockAutomationRegistry public registry;
    MockAutomationRegistrar public registrar;

    // Test addresses
    address public multiSig;
    address public member1;
    address public member2;
    address public member3;
    address public member4;
    address public nonMember;
    address public uniswapRouter;

    // Test parameters
    uint256 public constant CONTRIBUTION_AMOUNT = 100e6; // 100 PyUSD
    uint256 public constant COLLECTION_INTERVAL = 7 days;
    uint256 public constant DISTRIBUTION_INTERVAL = 28 days;
    uint256 public constant INITIAL_BALANCE = 10_000e6; // 10K PyUSD per member
    uint256 public constant INITIAL_LINK = 100 ether; // 100 LINK
    uint256 public constant INITIAL_ETH = 10 ether;

    // Events
    event ContributionDeposited(address indexed member, uint256 indexed contributionAmount);
    event ShareWithdrawn(address indexed member, uint256 indexed shareAmount);
    event WinnerPicked(address indexed winner);
    event FundsDeposited(address indexed funder, uint256 totalAmount, uint256 entropyAmount, uint256 linkAmount);
    event UpkeepFunded(uint256 indexed upkeepId, uint256 linkAmount);
    event UpkeepRegistered(uint256 indexed s_upkeepId);

    function setUp() public {
        // Setup test accounts
        multiSig = makeAddr("multiSig");
        member1 = makeAddr("member1");
        member2 = makeAddr("member2");
        member3 = makeAddr("member3");
        member4 = makeAddr("member4");
        nonMember = makeAddr("nonMember");
        uniswapRouter = makeAddr("uniswapRouter");

        // Deploy mock contracts
        pyUsd = new MockERC20("PayPal USD", "PYUSD", 6);
        link = new MockERC20("ChainLink Token", "LINK", 18);
        weth = new MockWETH();
        entropy = new MockEntropy();
        registry = new MockAutomationRegistry();
        registrar = new MockAutomationRegistrar(address(registry));

        // Setup committee config
        address[] memory members = new address[](4);
        members[0] = member1;
        members[1] = member2;
        members[2] = member3;
        members[3] = member4;

        Committee.CommitteeConfig memory config = Committee.CommitteeConfig({
            contributionAmount: CONTRIBUTION_AMOUNT,
            collectionInterval: COLLECTION_INTERVAL,
            distributionInterval: DISTRIBUTION_INTERVAL,
            members: members
        });

        Committee.ExternalContracts memory contracts = Committee.ExternalContracts({
            pyUsd: address(pyUsd),
            entropy: address(entropy),
            link: address(link),
            registrar: address(registrar),
            registry: address(registry),
            weth: address(weth)
        });

        // Deploy Committee
        committee = new Committee(config, contracts, multiSig);

        // Fund members with PyUSD and approve committee
        address[] memory allMembers = new address[](5);
        allMembers[0] = member1;
        allMembers[1] = member2;
        allMembers[2] = member3;
        allMembers[3] = member4;
        allMembers[4] = nonMember;

        for (uint256 i = 0; i < allMembers.length; i++) {
            pyUsd.mint(allMembers[i], INITIAL_BALANCE);
            vm.prank(allMembers[i]);
            pyUsd.approve(address(committee), type(uint256).max);
        }

        // Fund multiSig with LINK
        link.mint(multiSig, INITIAL_LINK);
        vm.prank(multiSig);
        link.approve(address(committee), type(uint256).max);

        // Fund committee with ETH for entropy
        vm.deal(address(committee), INITIAL_ETH);
    }

    // ============================================
    // Constructor Tests
    // ============================================

    function test_Constructor_SetsImmutables() public view {
        assertEq(address(committee.i_pyUsd()), address(pyUsd));
        assertEq(address(committee.i_entropy()), address(entropy));
        assertEq(address(committee.i_link()), address(link));
        assertEq(address(committee.i_registrar()), address(registrar));
        assertEq(address(committee.i_registry()), address(registry));
        assertEq(committee.i_weth(), address(weth));
        assertEq(committee.i_contributionAmount(), CONTRIBUTION_AMOUNT);
        assertEq(committee.i_collectionInterval(), COLLECTION_INTERVAL);
        assertEq(committee.i_distributionInterval(), DISTRIBUTION_INTERVAL);
        assertEq(committee.i_totalCycles(), 4);
    }

    function test_Constructor_SetsOwner() public view {
        assertEq(committee.owner(), multiSig);
    }

    function test_Constructor_InitializesState() public view {
        assertEq(uint8(committee.s_committeeState()), uint8(Committee.CommitteeState.OPEN));
        assertEq(committee.s_currentCycle(), 0);
        assertEq(committee.s_totalContribution(), 0);
        assertEq(committee.s_cycleContribution(), 0);
        assertEq(committee.s_lastDistributionTime(), block.timestamp);
    }

    function test_Constructor_RegistersMembers() public view {
        assertTrue(committee.s_isMember(member1));
        assertTrue(committee.s_isMember(member2));
        assertTrue(committee.s_isMember(member3));
        assertTrue(committee.s_isMember(member4));
        assertFalse(committee.s_isMember(nonMember));
    }

    function test_RevertWhen_Constructor_DuplicateMembers() public {
        address[] memory members = new address[](3);
        members[0] = member1;
        members[1] = member2;
        members[2] = member1; // Duplicate

        Committee.CommitteeConfig memory config = Committee.CommitteeConfig({
            contributionAmount: CONTRIBUTION_AMOUNT,
            collectionInterval: COLLECTION_INTERVAL,
            distributionInterval: DISTRIBUTION_INTERVAL,
            members: members
        });

        Committee.ExternalContracts memory contracts = Committee.ExternalContracts({
            pyUsd: address(pyUsd),
            entropy: address(entropy),
            link: address(link),
            registrar: address(registrar),
            registry: address(registry),
            weth: address(weth)
        });

        vm.expectRevert(Committee.Committee__DuplicateMembersNotAllowed.selector);
        new Committee(config, contracts, multiSig);
    }

    // ============================================
    // Deposit Contribution Tests
    // ============================================

    function test_DepositContribution_Success() public {
        vm.expectEmit(true, true, false, true);
        emit ContributionDeposited(member1, CONTRIBUTION_AMOUNT);

        vm.prank(member1);
        committee.depositContribution(CONTRIBUTION_AMOUNT);

        assertEq(committee.s_totalContribution(), CONTRIBUTION_AMOUNT);
        assertEq(committee.s_cycleContribution(), CONTRIBUTION_AMOUNT);
        assertEq(committee.s_totalContributionPerMember(member1), CONTRIBUTION_AMOUNT);
        assertEq(committee.s_cycleContributionPerMember(member1), CONTRIBUTION_AMOUNT);
        assertEq(pyUsd.balanceOf(address(committee)), CONTRIBUTION_AMOUNT);
    }

    function test_DepositContribution_AllMembers() public {
        vm.prank(member1);
        committee.depositContribution(CONTRIBUTION_AMOUNT);

        vm.prank(member2);
        committee.depositContribution(CONTRIBUTION_AMOUNT);

        vm.prank(member3);
        committee.depositContribution(CONTRIBUTION_AMOUNT);

        vm.prank(member4);
        committee.depositContribution(CONTRIBUTION_AMOUNT);

        assertEq(committee.s_totalContribution(), CONTRIBUTION_AMOUNT * 4);
        assertEq(committee.s_cycleContribution(), CONTRIBUTION_AMOUNT * 4);
        assertEq(pyUsd.balanceOf(address(committee)), CONTRIBUTION_AMOUNT * 4);
    }

    function test_RevertWhen_DepositContribution_NotMember() public {
        vm.prank(nonMember);
        vm.expectRevert(Committee.Committee__SenderIsNotMember.selector);
        committee.depositContribution(CONTRIBUTION_AMOUNT);
    }

    function test_RevertWhen_DepositContribution_WrongAmount() public {
        vm.prank(member1);
        vm.expectRevert(Committee.Committee__WrongContributionAmount.selector);
        committee.depositContribution(CONTRIBUTION_AMOUNT + 1);
    }

    function test_RevertWhen_DepositContribution_AlreadyContributed() public {
        vm.prank(member1);
        vm.warp(block.timestamp + 1);
        committee.depositContribution(CONTRIBUTION_AMOUNT);
        vm.warp(block.timestamp + 1);

        vm.prank(member1);
        vm.expectRevert(Committee.Committee__WaitForNextCycleToStart.selector);
        committee.depositContribution(CONTRIBUTION_AMOUNT);
    }

    function test_RevertWhen_DepositContribution_CycleOver() public completeAllDistributionCycles {
        vm.prank(member1);
        vm.expectRevert(Committee.Committee__CycleOver.selector);
        committee.depositContribution(CONTRIBUTION_AMOUNT);
    }

    // ============================================
    // Withdraw Share Tests
    // ============================================

    function test_WithdrawYourShare_Success() public completeFirstDistributionCycle {
        // Get the winner from the state
        address winner = _getWinnerFromState();
        uint256 expectedShare = (CONTRIBUTION_AMOUNT * 4) * 4;

        uint256 balanceBefore = pyUsd.balanceOf(winner);

        console.log(winner, expectedShare);

        vm.prank(winner);
        vm.expectEmit(true, true, false, false);
        emit ShareWithdrawn(winner, expectedShare);
        committee.withdrawYourShare();

        uint256 balanceAfter = pyUsd.balanceOf(winner);
        assertEq(balanceAfter - balanceBefore, expectedShare);
        assertTrue(committee.s_hasWithdrawn(winner));
    }

    function test_RevertWhen_WithdrawYourShare_NotMember() public {
        vm.prank(nonMember);
        vm.expectRevert(Committee.Committee__SenderIsNotMember.selector);
        committee.withdrawYourShare();
    }

    function test_RevertWhen_WithdrawYourShare_AlreadyWithdrawn() public completeFirstDistributionCycle {
        address winner = _getWinnerFromState();

        vm.prank(winner);
        committee.withdrawYourShare();

        vm.prank(winner);
        vm.expectRevert(Committee.Committee__AlreadyWithdrawn.selector);
        committee.withdrawYourShare();
    }

    function test_RevertWhen_WithdrawYourShare_NothingToWithdraw() public {
        vm.prank(member1);
        vm.expectRevert(Committee.Committee__NothingToWithdraw.selector);
        committee.withdrawYourShare();
    }

    function testEmergencyWithdrawWorks() public collectAllPaymentsForFirstCycle {
        vm.prank(multiSig);
        committee.emergencyWithdrawToMembers();
        assertEq(pyUsd.balanceOf(address(member1)), INITIAL_BALANCE);
        assertEq(pyUsd.balanceOf(address(member2)), INITIAL_BALANCE);
        assertEq(pyUsd.balanceOf(address(member3)), INITIAL_BALANCE);
        assertEq(pyUsd.balanceOf(address(member4)), INITIAL_BALANCE);

        /*s_totalContributionPerMember[msg.sender]
        s_cycleContributionPerMember[msg.sender]
        s_totalContribution
        s_cycleContribution*/

        assertEq(committee.s_totalContributionPerMember(member1), 0);
        assertEq(committee.s_cycleContributionPerMember(member1), 0);
        assertEq(committee.s_totalContributionPerMember(member2), 0);
        assertEq(committee.s_cycleContributionPerMember(member2), 0);
        assertEq(committee.s_totalContributionPerMember(member3), 0);
        assertEq(committee.s_cycleContributionPerMember(member3), 0);
        assertEq(committee.s_totalContributionPerMember(member4), 0);
        assertEq(committee.s_cycleContributionPerMember(member4), 0);

        assertEq(committee.s_totalContribution(), 0);
        assertEq(committee.s_cycleContribution(), 0);
    }

    // ============================================
    // CheckUpkeep Tests
    // ============================================

    function test_CheckUpkeep_ReturnsFalse_NoContributions() public {
        (bool upkeepNeeded,) = committee.checkUpkeep("");
        assertFalse(upkeepNeeded);
    }

    function test_CheckUpkeep_ReturnsFalse_NotAllContributed() public {
        vm.prank(member1);
        committee.depositContribution(CONTRIBUTION_AMOUNT);
        vm.prank(member2);
        committee.depositContribution(CONTRIBUTION_AMOUNT);

        vm.warp(block.timestamp + DISTRIBUTION_INTERVAL);

        (bool upkeepNeeded, bytes memory performData) = committee.checkUpkeep("");
        uint256 data = abi.decode(performData, (uint256));
        assertFalse(upkeepNeeded && data == 1);
    }

    function test_CheckUpkeep_ReturnsFalse_BeforeDistributionTime() public {
        _allMembersContribute();

        (bool upkeepNeeded,) = committee.checkUpkeep("");
        assertFalse(upkeepNeeded);
    }

    function test_CheckUpkeep_ReturnsTrue_AllConditionsMet() public {
        for (uint256 i = 0; i < 4; i++) {
            _allMembersContribute();
            vm.warp(block.timestamp + COLLECTION_INTERVAL);
            committee.performUpkeep(abi.encode(2));
        }

        (bool upkeepNeeded,) = committee.checkUpkeep("");
        assertTrue(upkeepNeeded);
    }

    function testCheckUpkeepReturnsFalseCycleEnded() public completeAllDistributionCycles {
        (bool upkeepNeeded,) = committee.checkUpkeep("");
        assertFalse(upkeepNeeded);
    }

    modifier completeAllDistributionCycles() {
        // Complete all cycles
        uint256 startTime = block.timestamp;
        uint64 sequenceNumber = 1;
        bytes memory completeDistributionCycle = abi.encode(1);
        bytes memory completeCollectionCycle = abi.encode(2);

        for (uint256 j = 0; j < 4; j++) {
            for (uint256 i = 0; i < 4; i++) {
                _allMembersContribute();
                vm.warp(block.timestamp + COLLECTION_INTERVAL);
                console.log("If true: ", block.timestamp >= startTime + DISTRIBUTION_INTERVAL);
                if (block.timestamp >= startTime + DISTRIBUTION_INTERVAL) {
                    console.log("Sequence number: ", sequenceNumber);
                    committee.performUpkeep(completeDistributionCycle);

                    if (sequenceNumber < 4) {
                        entropy.fulfillRequest(sequenceNumber, "");
                    }
                    startTime = block.timestamp;
                    sequenceNumber++;
                } else {
                    console.log("Performing cycle completion.");
                    committee.performUpkeep(completeCollectionCycle);
                }
            }
        }
        _;
    }

    // ============================================
    // PerformUpkeep Tests
    // ============================================

    modifier completeFirstDistributionCycle() {
        // Complete all cycles
        uint256 startTime = block.timestamp;
        bytes memory completeDistributionCycle = abi.encode(1);
        bytes memory completeCollectionCycle = abi.encode(2);
        for (uint256 i = 0; i < 4; i++) {
            _allMembersContribute();
            vm.warp(block.timestamp + COLLECTION_INTERVAL);
            console.log("If true: ", block.timestamp >= startTime + DISTRIBUTION_INTERVAL);
            if (block.timestamp >= startTime + DISTRIBUTION_INTERVAL) {
                vm.recordLogs();
                committee.performUpkeep(completeDistributionCycle);
                entropy.fulfillRequest(1, "");
                startTime = block.timestamp;
            } else {
                console.log("Performing cycle completion.");
                committee.performUpkeep(completeCollectionCycle);
            }
        }
        _;
    }

    modifier collectAllPaymentsForFirstCycle() {
        // Complete all cycles
        bytes memory completeCollectionCycle = abi.encode(2);
        for (uint256 i = 0; i < 4; i++) {
            _allMembersContribute();
            vm.warp(block.timestamp + COLLECTION_INTERVAL);
            committee.performUpkeep(completeCollectionCycle);
        }
        _;
    }

    function test_PerformUpkeep_Success() public completeFirstDistributionCycle {
        // Check state changes
        assertEq(committee.s_currentCycle(), 1);
        assertEq(committee.s_cycleContribution(), 0);

        // All cycle contributions should be reset
        assertEq(committee.s_cycleContributionPerMember(member1), 0);
        assertEq(committee.s_cycleContributionPerMember(member2), 0);
        assertEq(committee.s_cycleContributionPerMember(member3), 0);
        assertEq(committee.s_cycleContributionPerMember(member4), 0);
    }

    function test_PerformUpkeep_PicksWinner() public {
        // Complete all cycles
        uint256 startTime = block.timestamp;
        uint64 sequenceNumber = 1;

        for (uint256 i = 0; i < 4; i++) {
            _allMembersContribute();
            vm.warp(block.timestamp + COLLECTION_INTERVAL);

            if (block.timestamp >= startTime + DISTRIBUTION_INTERVAL) {
                vm.recordLogs();
                committee.performUpkeep(abi.encode(1));
                entropy.fulfillRequest(sequenceNumber, "");
                startTime = block.timestamp;
            } else {
                committee.performUpkeep(abi.encode(2));
            }
        }

        // Verify winner was picked by checking event
        address winner = _getWinnerFromLogs();
        assertTrue(winner != address(0));
        assertEq(committee.s_cycleDistributionPerMember(winner), (CONTRIBUTION_AMOUNT * 4) * 4);
    }

    function test_PerformUpkeep_LastCycleEndsCommittee() public completeAllDistributionCycles {
        assertEq(uint8(committee.s_committeeState()), uint8(Committee.CommitteeState.ENDED));
    }

    function test_RevertWhen_PerformUpkeep_UpkeepNotNeeded() public {
        vm.expectRevert(Committee.Committee__UpkeepNotNeeded.selector);
        committee.performUpkeep("");
    }

    function test_RevertWhen_PerformUpkeep_InsufficientETH() public collectAllPaymentsForFirstCycle {
        // Drain ETH from contract
        vm.prank(multiSig);
        committee.withdrawEth();

        vm.expectRevert(Committee.Committee__InsufficientFundsForRequest.selector);
        committee.performUpkeep(abi.encode(1));
    }

    // ============================================
    // Automation Funding Tests
    // ============================================

    function test_FundAutomationWithLink_RegistersUpkeep() public {
        uint96 linkAmount = 10 ether;

        vm.expectEmit(true, false, false, false);
        emit UpkeepRegistered(1);

        vm.prank(multiSig);
        committee.fundAutomationWithLink(linkAmount);

        assertTrue(committee.getUpkeepId() != 0);
    }

    function test_FundAutomationWithLink_AddsToExistingUpkeep() public {
        uint96 initialAmount = 10 ether;
        uint96 additionalAmount = 5 ether;

        // Register upkeep
        vm.prank(multiSig);
        committee.fundAutomationWithLink(initialAmount);

        uint256 upkeepId = committee.getUpkeepId();

        // Add more funds
        vm.expectEmit(true, false, false, true);
        emit UpkeepFunded(upkeepId, additionalAmount);

        vm.prank(multiSig);
        committee.fundAutomationWithLink(additionalAmount);
    }

    function test_RevertWhen_FundAutomationWithLink_ZeroAmount() public {
        vm.prank(multiSig);
        vm.expectRevert(Committee.Committee__InsufficientFunding.selector);
        committee.fundAutomationWithLink(0);
    }

    function test_RevertWhen_FundAutomationWithLink_BelowMinimum() public {
        vm.prank(multiSig);
        vm.expectRevert(Committee.Committee__InsufficientFunding.selector);
        committee.fundAutomationWithLink(1 ether); // Less than 5 ether minimum
    }

    function test_GetUpkeepBalance_ReturnsZero_NoUpkeep() public view {
        assertEq(committee.getUpkeepBalance(), 0);
    }

    function test_GetUpkeepBalance_ReturnsBalance_AfterFunding() public {
        uint96 linkAmount = 10 ether;

        vm.prank(multiSig);
        committee.fundAutomationWithLink(linkAmount);

        assertTrue(committee.getUpkeepBalance() > 0);
    }

    // ============================================
    // Emergency Withdraw Tests
    // ============================================

    function test_RevertWhen_EmergencyWithdraw_NotOwner() public {
        vm.prank(member1);
        vm.expectRevert();
        committee.emergencyWithdrawToMembers();
    }

    // ============================================
    // Withdrawal Tests (ETH and LINK)
    // ============================================

    function test_WithdrawEth_Success() public {
        uint256 ethAmount = 5 ether;
        vm.deal(address(committee), ethAmount);

        uint256 balanceBefore = multiSig.balance;

        vm.prank(multiSig);
        committee.withdrawEth();

        uint256 balanceAfter = multiSig.balance;
        assertEq(balanceAfter - balanceBefore, ethAmount);
        assertEq(address(committee).balance, 0);
    }

    function test_RevertWhen_WithdrawEth_NotOwner() public {
        vm.prank(member1);
        vm.expectRevert();
        committee.withdrawEth();
    }

    function test_WithdrawLink_Success() public {
        uint256 linkAmount = 50 ether;
        link.mint(address(committee), linkAmount);

        uint256 balanceBefore = link.balanceOf(multiSig);

        vm.prank(multiSig);
        committee.withdrawLink();

        uint256 balanceAfter = link.balanceOf(multiSig);
        assertEq(balanceAfter - balanceBefore, linkAmount);
        assertEq(link.balanceOf(address(committee)), 0);
    }

    function test_RevertWhen_WithdrawLink_NotOwner() public {
        vm.prank(member1);
        vm.expectRevert();
        committee.withdrawLink();
    }

    function test_FundEntropy_AcceptsETH() public {
        uint256 amount = 1 ether;
        uint256 balanceBefore = address(committee).balance;

        vm.deal(member1, amount);
        vm.prank(member1);
        committee.fundEntropy{value: amount}();

        assertEq(address(committee).balance - balanceBefore, amount);
    }

    function test_Receive_AcceptsETH() public {
        uint256 amount = 1 ether;
        uint256 balanceBefore = address(committee).balance;

        vm.deal(member1, amount);
        vm.prank(member1);
        (bool success,) = address(committee).call{value: amount}("");

        assertTrue(success);
        assertEq(address(committee).balance - balanceBefore, amount);
    }

    // ============================================
    // Full Cycle Integration Tests
    // ============================================

    /*function test_Integration_CompleteSingleCycle() public {
        // Cycle 0: All members contribute
        _allMembersContribute();
        assertEq(committee.s_currentCycle(), 0);
        assertEq(committee.s_cycleContribution(), CONTRIBUTION_AMOUNT * 4);

        // Wait for distribution time
        vm.warp(block.timestamp + DISTRIBUTION_INTERVAL);

        // Perform upkeep
        (bool upkeepNeeded,) = committee.checkUpkeep("");
        assertTrue(upkeepNeeded);

        committee.performUpkeep("");

        // Check cycle advanced
        assertEq(committee.s_currentCycle(), 1);
        assertEq(committee.s_cycleContribution(), 0);

        // Winner should be able to withdraw
        address winner = _getWinnerFromState();
        vm.prank(winner);
        committee.withdrawYourShare();

        assertEq(pyUsd.balanceOf(winner), INITIAL_BALANCE - CONTRIBUTION_AMOUNT + (CONTRIBUTION_AMOUNT * 4));
    }

    function test_Integration_CompleteAllCycles() public {
        address[] memory winners = new address[](4);

        for (uint256 cycle = 0; cycle < 4; cycle++) {
            // All members contribute
            _allMembersContribute();

            // Wait for distribution
            vm.warp(block.timestamp + DISTRIBUTION_INTERVAL);

            // Perform upkeep
            committee.performUpkeep("");

            // Get and record winner
            winners[cycle] = _getWinnerFromState();

            // Winner withdraws
            vm.prank(winners[cycle]);
            committee.withdrawYourShare();

            // Advance to next cycle
            if (cycle < 3) {
                vm.warp(block.timestamp + COLLECTION_INTERVAL);
            }
        }

        // Verify all cycles completed
        assertEq(committee.s_currentCycle(), 4);
        assertEq(uint8(committee.s_committeeState()), uint8(Committee.CommitteeState.ENDED));

        // Verify all winners got their share
        for (uint256 i = 0; i < 4; i++) {
            assertTrue(committee.s_hasWithdrawn(winners[i]));
        }
    }

    function test_Integration_MemberBalancesAfterFullCycle() public {
        uint256[] memory initialBalances = new uint256[](4);
        initialBalances[0] = pyUsd.balanceOf(member1);
        initialBalances[1] = pyUsd.balanceOf(member2);
        initialBalances[2] = pyUsd.balanceOf(member3);
        initialBalances[3] = pyUsd.balanceOf(member4);

        // Complete all cycles
        for (uint256 cycle = 0; cycle < 4; cycle++) {
            _allMembersContribute();
            vm.warp(block.timestamp + DISTRIBUTION_INTERVAL);
            committee.performUpkeep("");

            address winner = _getWinnerFromState();
            vm.prank(winner);
            committee.withdrawYourShare();

            if (cycle < 3) {
                vm.warp(block.timestamp + COLLECTION_INTERVAL);
            }
        }

        // Each member should have their initial balance (contributed 4x, won 1x)
        assertEq(pyUsd.balanceOf(member1), initialBalances[0]);
        assertEq(pyUsd.balanceOf(member2), initialBalances[1]);
        assertEq(pyUsd.balanceOf(member3), initialBalances[2]);
        assertEq(pyUsd.balanceOf(member4), initialBalances[3]);
    }*/

    // ============================================
    // Helper Functions
    // ============================================

    function _allMembersContribute() internal {
        vm.prank(member1);
        committee.depositContribution(CONTRIBUTION_AMOUNT);
        vm.prank(member2);
        committee.depositContribution(CONTRIBUTION_AMOUNT);
        vm.prank(member3);
        committee.depositContribution(CONTRIBUTION_AMOUNT);
        vm.prank(member4);
        committee.depositContribution(CONTRIBUTION_AMOUNT);
    }

    function _getWinnerFromState() internal view returns (address) {
        // Check each member to find who has a distribution amount
        if (committee.s_cycleDistributionPerMember(member1) > 0) return member1;
        if (committee.s_cycleDistributionPerMember(member2) > 0) return member2;
        if (committee.s_cycleDistributionPerMember(member3) > 0) return member3;
        if (committee.s_cycleDistributionPerMember(member4) > 0) return member4;
        return address(0);
    }

    function _getWinnerFromLogs() internal returns (address) {
        Vm.Log[] memory logs = vm.getRecordedLogs();

        for (uint256 i = 0; i < logs.length; i++) {
            if (logs[i].topics[0] == keccak256("WinnerPicked(address)")) {
                return address(uint160(uint256(logs[i].topics[1])));
            }
        }
        return address(0);
    }
}
