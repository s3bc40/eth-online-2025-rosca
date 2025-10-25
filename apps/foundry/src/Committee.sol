// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {AutomationCompatibleInterface} from
    "@chainlink/contracts/src/v0.8/automation/interfaces/AutomationCompatibleInterface.sol";
import {IEntropyConsumer} from "@pythnetwork/entropy-sdk-solidity/IEntropyConsumer.sol";
import {IAutomationRegistrar, IAutomationRegistry} from "./Interface/IAutomationRegistrarAndRegistry.sol";
import {IPyUsd} from "./Interface/IPyUsd.sol";
import {IEntropyV2} from "@pythnetwork/entropy-sdk-solidity/IEntropyV2.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Committee Contract
 * @author 0xusmanf
 * @notice Implements a rotating savings and credit association (ROSCA) mechanism and chooses a random winner
 * every `distributionInterval`.
 * @dev Integrates Chainlink Automation for time-based upkeep and Pyth Entropy for verifiable randomness.
 */
contract Committee is Ownable, AutomationCompatibleInterface, IEntropyConsumer {
    //--------- Errors ---------//
    error Committee__CycleOver();
    error Committee__DepositFailed();
    error Committee__WithdrawFailed();
    error Committee__UpkeepNotNeeded();
    error Committee__AlreadyWithdrawn();
    error Committee__NothingToWithdraw();
    error Committee__EthTransferFailed();
    error Committee__SenderIsNotMember();
    error Committee__WaitForNextCycleToStart();
    error Committee__WrongContributionAmount();
    error Committee__DuplicateMembersNotAllowed();
    error Committee__InsufficientFunding();
    error Committee__LinkTransferFailed();
    error Committee__UpkeepNotRegistered();
    error Committee__InsufficientFundsForRequest();
    error Committee__WinnerSelectionInProgress();

    //--------- Type Declarations ---------//

    /**
     * @notice Struct to hold committee configuration parameters
     */
    struct CommitteeConfig {
        uint256 contributionAmount;
        uint256 collectionInterval;
        uint256 distributionInterval;
        address[] members;
    }

    /**
     * @notice Struct to hold external contract addresses
     */
    struct ExternalContracts {
        address pyUsd;
        address entropy;
        address link;
        address registrar;
        address registry;
        address weth;
    }

    enum CommitteeState {
        OPEN,
        SELECTING_WINNER,
        ENDED
    }

    //--------- Constants ---------//
    bytes public constant BLANK = "";

    //--------- Immutables ---------//
    IPyUsd public immutable i_pyUsd;
    IEntropyV2 public immutable i_entropy;
    LinkTokenInterface public immutable i_link;
    IAutomationRegistrar public immutable i_registrar;
    IAutomationRegistry public immutable i_registry;
    address public immutable i_weth;
    uint8 public immutable i_totalCycles;
    uint256 public immutable i_contributionAmount;
    uint256 public immutable i_collectionInterval;
    uint256 public immutable i_distributionInterval;

    //--------- State Variables ---------//
    uint8 public s_currentCycle;
    uint256 public s_lastDistributionTime;
    uint256 public s_cycleStartTime;
    uint256 public s_totalContribution;
    uint256 public s_cycleContribution;
    uint256 public s_numberOfContributionsPerCycle;
    uint256 public s_upkeepId;
    address[] public s_members;
    address[] public s_remainingWinners;
    CommitteeState public s_committeeState;
    mapping(address => uint256) public s_lastContributionTime;
    mapping(address => uint256) public s_totalContributionPerMember;
    mapping(address => uint256) public s_cycleContributionPerMember;
    mapping(address => uint256) public s_cycleDistributionPerMember;
    mapping(address => bool) public s_hasWithdrawn;
    mapping(address => bool) public s_isMember;

    //--------- Events ---------//
    event ContributionDeposited(address indexed member, uint256 indexed contributionAmount);
    event ShareWithdrawn(address indexed member, uint256 indexed shareAmount);
    event WinnerPicked(address indexed winner);
    event UpkeepFunded(uint256 indexed upkeepId, uint256 linkAmount);
    event UpkeepRegistered(uint256 indexed s_upkeepId);

    //--------- Test Events ---------//
    event timeStamp(uint256 indexed lastDepositTime, uint256 indexed cycleStartTime);

    /**
     * @notice Initializes the committee with configuration and external contracts
     * @param config Committee configuration parameters
     * @param contracts External contract addresses
     * @param _multiSigAccount Address of the multisig owner
     */
    constructor(CommitteeConfig memory config, ExternalContracts memory contracts, address _multiSigAccount)
        Ownable(_multiSigAccount)
    {
        //--------- Immutables Assignments ---------//
        i_pyUsd = IPyUsd(contracts.pyUsd);
        i_entropy = IEntropyV2(contracts.entropy);
        i_contributionAmount = config.contributionAmount;
        i_collectionInterval = config.collectionInterval;
        i_distributionInterval = config.distributionInterval;
        i_totalCycles = uint8(config.members.length);
        i_link = LinkTokenInterface(contracts.link);
        i_registrar = IAutomationRegistrar(contracts.registrar);
        i_registry = IAutomationRegistry(contracts.registry);
        i_weth = contracts.weth;

        //--------- State Variable Assignments ---------//
        s_numberOfContributionsPerCycle = config.distributionInterval / config.collectionInterval;
        s_committeeState = CommitteeState.OPEN;
        s_lastDistributionTime = block.timestamp;
        s_cycleStartTime = block.timestamp;
        s_members = config.members;
        s_remainingWinners = config.members;
        uint256 i;
        for (; i < config.members.length;) {
            if (s_isMember[s_members[i]] == true) {
                revert Committee__DuplicateMembersNotAllowed();
            }
            s_isMember[s_members[i]] = true;
            unchecked {
                ++i;
            }
        }
    }

    receive() external payable {}

    function performUpkeep(bytes calldata performData) external override {
        (bool upkeepNeeded,) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Committee__UpkeepNotNeeded();
        }

        uint256 functionId = abi.decode(performData, (uint256));

        if (functionId == 1) {
            s_committeeState = CommitteeState.SELECTING_WINNER;
            if (s_remainingWinners.length > 1) {
                uint128 requestFee = i_entropy.getFeeV2();
                if (address(this).balance < requestFee) {
                    revert Committee__InsufficientFundsForRequest();
                }
                uint64 sequenceNumber = i_entropy.requestV2{value: requestFee}();
            } else {
                s_lastDistributionTime = block.timestamp;
                s_currentCycle += 1;
                uint256 totalMembers = s_members.length;
                uint256 i;
                for (; i < totalMembers;) {
                    s_cycleContributionPerMember[s_members[i]] = 0;
                    unchecked {
                        ++i;
                    }
                }
                s_cycleDistributionPerMember[s_members[0]] = s_cycleContribution;
                s_remainingWinners.pop();
                s_cycleContribution = 0;
                emit WinnerPicked(s_members[0]);
                s_committeeState = CommitteeState.ENDED;
            }
        } else if (functionId == 2) {
            s_cycleStartTime = block.timestamp;
        }
    }

    /**
     * @notice Alternative funding method - deposit LINK directly
     * @param _linkAmount Amount of LINK to deposit
     */
    function fundAutomationWithLink(uint96 _linkAmount) external {
        if (_linkAmount == 0) {
            revert Committee__InsufficientFunding();
        }

        // Transfer LINK from sender
        bool success = i_link.transferFrom(msg.sender, address(this), _linkAmount);
        if (!success) {
            revert Committee__LinkTransferFailed();
        }

        if (s_upkeepId == 0) {
            _registerUpkeep(_linkAmount);
        } else {
            _addFundsToUpkeep(_linkAmount);
        }
    }

    /**
     * @notice Withdraws excess LINK to owner
     */
    function withdrawLink() external onlyOwner {
        uint256 balance = i_link.balanceOf(address(this));
        bool success = i_link.transfer(owner(), balance);
        if (!success) {
            revert Committee__LinkTransferFailed();
        }
    }

    /**
     * @notice Allows a winning member to withdraw their distributed share.
     * @dev Prevents multiple withdrawals per cycle.
     */
    function withdrawYourShare() external {
        uint256 share = s_cycleDistributionPerMember[msg.sender];
        //--------- Checks ---------//
        if (!s_isMember[msg.sender]) {
            revert Committee__SenderIsNotMember();
        }
        if (s_hasWithdrawn[msg.sender]) {
            revert Committee__AlreadyWithdrawn();
        }
        if (share == 0) {
            revert Committee__NothingToWithdraw();
        }

        //--------- Effects ---------//
        s_hasWithdrawn[msg.sender] = true;
        emit ShareWithdrawn(msg.sender, share);

        //--------- Interaction ---------//
        bool success = i_pyUsd.transfer(msg.sender, share);
        if (!success) {
            revert Committee__WithdrawFailed();
        }
    }

    /**
     * @notice Withdraws all PYUSD held by the contract to the members.
     */
    function emergencyWithdrawToMembers() external onlyOwner {
        if (s_committeeState == CommitteeState.SELECTING_WINNER) {
            revert Committee__WinnerSelectionInProgress();
        }
        uint256 totalMembers = s_members.length;
        s_cycleContribution = 0;
        uint256 i;
        for (; i < totalMembers;) {
            uint256 share = s_cycleContributionPerMember[s_members[i]];
            if (share != 0) {
                s_totalContributionPerMember[s_members[i]] -= share;
                s_cycleContributionPerMember[s_members[i]] = 0;
                s_totalContribution -= share;
                bool success = i_pyUsd.transfer(s_members[i], share);
                if (!success) {
                    revert Committee__WithdrawFailed();
                }
            }
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Allows a member to deposit their contribution for the current cycle.
     * @param _contributionAmount The amount being contributed (must match `i_contributionAmount`).
     * @dev Transfers tokens from the sender to this contract.
     */
    function depositContribution(uint256 _contributionAmount) external {
        //--------- Checks ---------//
        if (!s_isMember[msg.sender]) {
            revert Committee__SenderIsNotMember();
        }
        if (_contributionAmount != i_contributionAmount) {
            revert Committee__WrongContributionAmount();
        }
        if (s_currentCycle >= i_totalCycles) {
            revert Committee__CycleOver();
        }
        emit timeStamp(s_lastContributionTime[msg.sender], s_cycleStartTime);
        if (s_lastContributionTime[msg.sender] >= s_cycleStartTime) {
            revert Committee__WaitForNextCycleToStart();
        }

        //--------- Effects ---------//
        s_lastContributionTime[msg.sender] = block.timestamp;
        s_totalContributionPerMember[msg.sender] += i_contributionAmount;
        s_cycleContributionPerMember[msg.sender] += i_contributionAmount;
        s_totalContribution += i_contributionAmount;
        s_cycleContribution += i_contributionAmount;
        emit ContributionDeposited(msg.sender, i_contributionAmount);

        //--------- Interaction ---------//
        bool success = i_pyUsd.transferFrom(msg.sender, address(this), i_contributionAmount);
        if (!success) {
            revert Committee__DepositFailed();
        }
    }

    /**
     * @notice Withdraws all ETH held by the contract to the owner.
     */
    function withdrawEth() external onlyOwner {
        (bool success,) = payable(owner()).call{value: address(this).balance}("");
        if (!success) {
            revert Committee__EthTransferFailed();
        }
    }

    /**
     * @notice Allows anyone to send ETH to fund randomness fees.
     */
    function fundEntropy() external payable {}

    function checkUpkeep(bytes memory /* checkData */ )
        public
        override
        returns (bool upkeepNeeded, bytes memory /* performData */ )
    {
        bool isDistributionTime = _isDistributionTime();
        bool hasEveryoneContributed =
            s_cycleContribution == ((s_members.length * i_contributionAmount) * s_numberOfContributionsPerCycle);
        bool cycleHasNotEnded = s_currentCycle < i_totalCycles;
        bool checkUpkeep1 = (
            isDistributionTime && hasEveryoneContributed && cycleHasNotEnded && s_committeeState == CommitteeState.OPEN
        );
        bool checkUpkeep2 =
            (s_cycleStartTime + i_collectionInterval <= block.timestamp && s_committeeState == CommitteeState.OPEN);

        if (checkUpkeep1) {
            return (true, abi.encode(uint256(1)));
        } else if (checkUpkeep2) {
            return (true, abi.encode(uint256(2)));
        }

        return (false, "");
    }

    function entropyCallback(uint64 sequenceNumber, address _providerAddress, bytes32 randomNumber) internal override {
        {
            s_lastDistributionTime = block.timestamp;
            s_currentCycle += 1;
            s_cycleStartTime = block.timestamp;
            uint256 totalMembers = s_members.length;
            uint256 i;
            for (; i < totalMembers;) {
                s_cycleContributionPerMember[s_members[i]] = 0;
                unchecked {
                    ++i;
                }
            }
        }

        address winner;
        uint256 totalRemainingWinners = s_remainingWinners.length;
        uint256 index = uint256(randomNumber) % totalRemainingWinners;
        winner = s_remainingWinners[index];
        if (!(index == totalRemainingWinners - 1)) {
            s_remainingWinners[index] = s_remainingWinners[totalRemainingWinners - 1];
        }
        s_remainingWinners.pop();
        s_cycleDistributionPerMember[winner] = s_cycleContribution;
        emit WinnerPicked(winner);
        s_cycleContribution = 0;
        s_committeeState = CommitteeState.OPEN;
        s_cycleStartTime = block.timestamp;
    }

    function getEntropy() internal view override returns (address) {
        return address(i_entropy);
    }

    /**
     * @notice Internal helper that checks if the distribution interval has passed.
     * @return True if its time to select a winner and new distribution cycle to start.
     */
    function _isDistributionTime() internal view returns (bool) {
        return block.timestamp >= s_lastDistributionTime + i_distributionInterval;
    }

    /**
     * @notice Registers a new Chainlink Automation upkeep
     * @param _linkAmount Amount of LINK for initial funding
     */
    function _registerUpkeep(uint96 _linkAmount) private {
        if (_linkAmount < 5 ether) {
            revert Committee__InsufficientFunding();
        }

        IAutomationRegistrar.RegistrationParams memory params = IAutomationRegistrar.RegistrationParams({
            name: string(abi.encodePacked("Committee_", address(this))),
            encryptedEmail: BLANK,
            upkeepContract: address(this),
            gasLimit: 1_000_000,
            adminAddress: owner(),
            triggerType: 0,
            checkData: BLANK,
            triggerConfig: BLANK,
            offchainConfig: BLANK,
            amount: _linkAmount
        });

        // Approve LINK to registrar
        i_link.approve(address(i_registrar), _linkAmount);

        // Register upkeep
        s_upkeepId = i_registrar.registerUpkeep(params);

        if (s_upkeepId == 0) {
            revert Committee__UpkeepNotRegistered();
        }

        emit UpkeepRegistered(s_upkeepId);
    }

    /**
     * @notice Adds LINK funds to existing upkeep
     * @param _linkAmount Amount of LINK to add
     */
    function _addFundsToUpkeep(uint96 _linkAmount) private {
        if (s_upkeepId == 0) {
            revert Committee__UpkeepNotRegistered();
        }

        // Approve LINK to registry
        i_link.approve(address(i_registry), _linkAmount);

        // Add funds
        i_registry.addFunds(s_upkeepId, _linkAmount);

        emit UpkeepFunded(s_upkeepId, _linkAmount);
    }

    /**
     * @notice Returns current upkeep balance
     */
    function getUpkeepBalance() external view returns (uint96) {
        if (s_upkeepId == 0) return 0;
        return i_registry.getUpkeep(s_upkeepId).balance;
    }

    /**
     * @notice Get upkeep ID for this committee
     */
    function getUpkeepId() external view returns (uint256) {
        return s_upkeepId;
    }
}
