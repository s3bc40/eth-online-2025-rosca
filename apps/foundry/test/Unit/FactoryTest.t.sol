// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {Factory} from "../../src/Factory.sol";
import {Committee} from "../../src/Committee.sol";
import {MockERC20} from "../Mocks/MockERC20.sol";
import {MockWETH} from "../Mocks/MockWeth.sol";
import {MockEntropy} from "../Mocks/MockEntropy.sol";
import {CommitteeDeployer} from "../../src/CommitteeDeployer.sol";
import {MockAutomationRegistrar, MockAutomationRegistry} from "../Mocks/MockAutomationRegistrarAndRegistry.sol";

contract FactoryTest is Test {
    Factory public factory;

    // Mock contracts
    MockERC20 public pyUsd;
    MockERC20 public link;
    MockWETH public weth;
    MockEntropy public entropy;
    MockAutomationRegistry public registry;
    MockAutomationRegistrar public registrar;

    // Test addresses
    address public owner;
    address public multiSig1;
    address public multiSig2;
    address public member1;
    address public member2;
    address public member3;
    address public member4;
    address public member5;

    // Test parameters
    uint8 public constant MAX_COMMITTEE_MEMBERS = 10;
    uint256 public constant CONTRIBUTION_AMOUNT = 100e6; // 100 PyUSD
    uint256 public constant COLLECTION_INTERVAL = 7 days;
    uint256 public constant DISTRIBUTION_INTERVAL = 30 days;

    // Events
    event CommitteeCreated(address indexed multiSigAccount, address indexed committee);
    event MaxCommitteeMembersUpdated(uint96 newMax);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function setUp() public {
        // Setup test accounts
        owner = address(this);
        multiSig1 = makeAddr("multiSig1");
        multiSig2 = makeAddr("multiSig2");
        member1 = makeAddr("member1");
        member2 = makeAddr("member2");
        member3 = makeAddr("member3");
        member4 = makeAddr("member4");
        member5 = makeAddr("member5");

        // Deploy mock contracts
        pyUsd = new MockERC20("PayPal USD", "PYUSD", 6);
        link = new MockERC20("ChainLink Token", "LINK", 18);
        weth = new MockWETH();
        entropy = new MockEntropy();
        registry = new MockAutomationRegistry();
        registrar = new MockAutomationRegistrar(address(registry));

        // Deploy Factory
        factory = new Factory(
            address(pyUsd),
            address(entropy),
            address(link),
            address(registrar),
            address(registry),
            address(weth),
            MAX_COMMITTEE_MEMBERS,
            address(new CommitteeDeployer())
        );
    }

    // ============================================
    // Constructor Tests
    // ============================================

    function testConstructorSetsAllVariables() public view {
        assertEq(factory.i_PyUsd(), address(pyUsd));
        assertEq(factory.i_entropy(), address(entropy));
        assertEq(factory.i_link(), address(link));
        assertEq(factory.i_registrar(), address(registrar));
        assertEq(factory.i_registry(), address(registry));
        assertEq(factory.i_weth(), address(weth));
        assertEq(factory.maxCommitteeMembers(), MAX_COMMITTEE_MEMBERS);
        assertEq(factory.owner(), owner);
    }

    // ============================================
    // Create Committee Tests - Success Cases
    // ============================================

    function testCreateCommitteeSuccess() public {
        address[] memory members = new address[](3);
        members[0] = member1;
        members[1] = member2;
        members[2] = member3;

        vm.expectEmit(true, false, false, false);
        emit CommitteeCreated(multiSig1, address(0));

        address committeeAddr =
            factory.createCommittee(CONTRIBUTION_AMOUNT, COLLECTION_INTERVAL, DISTRIBUTION_INTERVAL, members, multiSig1);

        assertTrue(committeeAddr != address(0));
    }

    function testCreateCommitteeStoresCommitteeAddress() public {
        address[] memory members = new address[](3);
        members[0] = member1;
        members[1] = member2;
        members[2] = member3;

        address committeeAddr =
            factory.createCommittee(CONTRIBUTION_AMOUNT, COLLECTION_INTERVAL, DISTRIBUTION_INTERVAL, members, multiSig1);

        address[] memory committees = factory.getCommittees(multiSig1);
        assertEq(committees.length, 1);
        assertEq(committees[0], committeeAddr);
    }

    function testCreateCommitteeIncreasesCommitteeCount() public {
        address[] memory members = new address[](3);
        members[0] = member1;
        members[1] = member2;
        members[2] = member3;

        assertEq(factory.getCommitteeCount(multiSig1), 0);

        factory.createCommittee(CONTRIBUTION_AMOUNT, COLLECTION_INTERVAL, DISTRIBUTION_INTERVAL, members, multiSig1);

        assertEq(factory.getCommitteeCount(multiSig1), 1);
    }

    function testCreateCommitteeSetsLatestCommittee() public {
        address[] memory members = new address[](3);
        members[0] = member1;
        members[1] = member2;
        members[2] = member3;

        address committeeAddr =
            factory.createCommittee(CONTRIBUTION_AMOUNT, COLLECTION_INTERVAL, DISTRIBUTION_INTERVAL, members, multiSig1);

        assertEq(factory.getLatestCommittee(multiSig1), committeeAddr);
    }

    function testCreateCommitteeWithMaxMembers() public {
        address[] memory members = new address[](MAX_COMMITTEE_MEMBERS);
        for (uint256 i = 0; i < MAX_COMMITTEE_MEMBERS; i++) {
            members[i] = makeAddr(string(abi.encodePacked("member", i)));
        }

        address committeeAddr =
            factory.createCommittee(CONTRIBUTION_AMOUNT, COLLECTION_INTERVAL, DISTRIBUTION_INTERVAL, members, multiSig1);

        assertTrue(committeeAddr != address(0));
    }

    function testCreateCommitteeMultipleDifferentMultiSigs() public {
        address[] memory members = new address[](2);
        members[0] = member1;
        members[1] = member2;

        address committee1 =
            factory.createCommittee(CONTRIBUTION_AMOUNT, COLLECTION_INTERVAL, DISTRIBUTION_INTERVAL, members, multiSig1);

        address committee2 =
            factory.createCommittee(CONTRIBUTION_AMOUNT, COLLECTION_INTERVAL, DISTRIBUTION_INTERVAL, members, multiSig2);

        assertEq(factory.getCommitteeCount(multiSig1), 1);
        assertEq(factory.getCommitteeCount(multiSig2), 1);
        assertFalse(committee1 == committee2);
    }

    /*function testCreateCommitteeAfterPreviousEnded() public {
        address[] memory members = new address[](2);
        members[0] = member1;
        members[1] = member2;

        // Create first committee
        address committee1 =
            factory.createCommittee(CONTRIBUTION_AMOUNT, COLLECTION_INTERVAL, DISTRIBUTION_INTERVAL, members, multiSig1);

        // Mock the committee state as ENDED
        Committee committeeContract = Committee(payable(committee1));
        // Note: You'll need to actually end the committee through proper means
        // This is just for testing the factory logic
        vm.mockCall(
            committee1,
            abi.encodeWithSelector(Committee.s_committeeState.selector),
            abi.encode(Committee.CommitteeState.ENDED)
        );

        // Should be able to create another committee
        address committee2 =
            factory.createCommittee(CONTRIBUTION_AMOUNT, COLLECTION_INTERVAL, DISTRIBUTION_INTERVAL, members, multiSig1);

        assertEq(factory.getCommitteeCount(multiSig1), 2);
        assertFalse(committee1 == committee2);
    }*/

    // ============================================
    // Create Committee Tests - Failure Cases
    // ============================================

    function testRevertWhenCreateCommitteeExceedsMaxMembers() public {
        address[] memory members = new address[](MAX_COMMITTEE_MEMBERS + 1);
        for (uint256 i = 0; i < MAX_COMMITTEE_MEMBERS + 1; i++) {
            members[i] = makeAddr(string(abi.encodePacked("member", i)));
        }

        vm.expectRevert(Factory.Factory__MaxCommitteeMembersExceeded.selector);
        factory.createCommittee(CONTRIBUTION_AMOUNT, COLLECTION_INTERVAL, DISTRIBUTION_INTERVAL, members, multiSig1);
    }

    function testRevertWhenCreateCommitteeActiveCommitteeExists() public {
        address[] memory members = new address[](2);
        members[0] = member1;
        members[1] = member2;

        // Create first committee
        address committee1 =
            factory.createCommittee(CONTRIBUTION_AMOUNT, COLLECTION_INTERVAL, DISTRIBUTION_INTERVAL, members, multiSig1);

        // Try to create another while first is active
        vm.expectRevert(abi.encodeWithSelector(Factory.Factory__CommitteeAlreadyActive.selector, committee1));
        factory.createCommittee(CONTRIBUTION_AMOUNT, COLLECTION_INTERVAL, DISTRIBUTION_INTERVAL, members, multiSig1);
    }

    // ============================================
    // Update Max Committee Members Tests
    // ============================================

    function testUpdateMaxCommitteeMembersSuccess() public {
        uint8 newMax = 20;

        vm.expectEmit(true, false, false, true);
        emit MaxCommitteeMembersUpdated(newMax);

        factory.updateMaxCommitteeMembers(newMax);

        assertEq(factory.maxCommitteeMembers(), newMax);
    }

    function testUpdateMaxCommitteeMembersToZeroRevert() public {
        vm.expectRevert(Factory.Factory__CanNotBeLessThanFive.selector);
        factory.updateMaxCommitteeMembers(0);
    }

    function testUpdateMaxCommitteeMembersToMaxUint8() public {
        factory.updateMaxCommitteeMembers(type(uint8).max);
        assertEq(factory.maxCommitteeMembers(), type(uint8).max);
    }

    function testRevertWhenUpdateMaxCommitteeMembersNotOwner() public {
        address nonOwner = makeAddr("nonOwner");

        vm.prank(nonOwner);
        vm.expectRevert();
        factory.updateMaxCommitteeMembers(20);
    }

    // ============================================
    // Getter Function Tests
    // ============================================

    function test_GetCommittees_EmptyArray() public view {
        address[] memory committees = factory.getCommittees(multiSig1);
        assertEq(committees.length, 0);
    }

    /*function testGetCommitteesMultipleCommittees() public {
        address[] memory members = new address[](2);
        members[0] = member1;
        members[1] = member2;

        // Create first committee and mock it as ended
        address committee1 =
            factory.createCommittee(CONTRIBUTION_AMOUNT, COLLECTION_INTERVAL, DISTRIBUTION_INTERVAL, members, multiSig1);

        vm.mockCall(
            committee1,
            abi.encodeWithSelector(Committee.s_CommitteeState.selector),
            abi.encode(Committee.CommitteeState.ENDED)
        );

        // Create second committee
        address committee2 =
            factory.createCommittee(CONTRIBUTION_AMOUNT, COLLECTION_INTERVAL, DISTRIBUTION_INTERVAL, members, multiSig1);

        address[] memory committees = factory.getCommittees(multiSig1);
        assertEq(committees.length, 2);
        assertEq(committees[0], committee1);
        assertEq(committees[1], committee2);
    }*/

    /*function testGetLatestCommitteeNoCommittees() public view {
        assertEq(factory.getLatestCommittee(multiSig1), address(0));
    }

    function testGetLatestCommitteeReturnsLastCommittee() public {
        address[] memory members = new address[](2);
        members[0] = member1;
        members[1] = member2;

        address committee1 =
            factory.createCommittee(CONTRIBUTION_AMOUNT, COLLECTION_INTERVAL, DISTRIBUTION_INTERVAL, members, multiSig1);

        vm.mockCall(
            committee1,
            abi.encodeWithSelector(Committee.s_CommitteeState.selector),
            abi.encode(Committee.CommitteeState.ENDED)
        );

        address committee2 =
            factory.createCommittee(CONTRIBUTION_AMOUNT, COLLECTION_INTERVAL, DISTRIBUTION_INTERVAL, members, multiSig1);

        assertEq(factory.getLatestCommittee(multiSig1), committee2);
    }*/

    /*function testGetCommitteeCountMultiple() public {
        address[] memory members = new address[](2);
        members[0] = member1;
        members[1] = member2;

        address committee1 =
            factory.createCommittee(CONTRIBUTION_AMOUNT, COLLECTION_INTERVAL, DISTRIBUTION_INTERVAL, members, multiSig1);

        vm.mockCall(
            committee1,
            abi.encodeWithSelector(Committee.s_CommitteeState.selector),
            abi.encode(Committee.CommitteeState.ENDED)
        );

        factory.createCommittee(CONTRIBUTION_AMOUNT, COLLECTION_INTERVAL, DISTRIBUTION_INTERVAL, members, multiSig1);

        assertEq(factory.getCommitteeCount(multiSig1), 2);
    }*/

    // ============================================
    // Ownership Tests
    // ============================================

    function testTransferOwnershipSuccess() public {
        address newOwner = makeAddr("newOwner");

        vm.expectEmit(true, true, false, false);
        emit OwnershipTransferred(owner, newOwner);

        factory.transferOwnership(newOwner);

        assertEq(factory.owner(), newOwner);
    }

    function testRenounceOwnershipSuccess() public {
        factory.renounceOwnership();
        assertEq(factory.owner(), address(0));
    }

    function testRevertWhenTransferOwnershipNotOwner() public {
        address nonOwner = makeAddr("nonOwner");
        address newOwner = makeAddr("newOwner");

        vm.prank(nonOwner);
        vm.expectRevert();
        factory.transferOwnership(newOwner);
    }
}
