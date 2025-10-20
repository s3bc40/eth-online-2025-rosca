// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IPyUsd} from "./Interface/IPyUsd.sol";
import {IAutomationRegistrar, IAutomationRegistry} from "./Interface/IAutomationRegistrarAndRegistry.sol";
import {IUniswapV2Router} from "./Interface/IUniswapV2Router.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IEntropyV2} from "@pythnetwork/entropy-sdk-solidity/IEntropyV2.sol";
import {IEntropyConsumer} from "@pythnetwork/entropy-sdk-solidity/IEntropyConsumer.sol";
import {AutomationCompatibleInterface} from
    "@chainlink/contracts/src/v0.8/automation/interfaces/AutomationCompatibleInterface.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";

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
    error Committee__SwapFailed();
    error Committee__InvalidPercentage();
    error Committee__InsufficientFundsForRequest();

    bytes public constant BLANK = "";

    //--------- Immutables ---------//
    IPyUsd public immutable i_pyUsd;
    IEntropyV2 public immutable i_entropy;
    LinkTokenInterface public immutable i_link;
    IAutomationRegistrar public immutable i_registrar;
    IAutomationRegistry public immutable i_registry;
    IUniswapV2Router public immutable i_uniswapRouter;
    address public immutable i_weth;
    uint256 public immutable i_totalCycles;
    uint256 public immutable i_contributionAmount;
    uint256 public immutable i_collectionInterval;
    uint256 public immutable i_distributionInterval;

    //--------- State Variables ---------//
    uint256 public s_currentCycle;
    uint256 public s_lastDistributionTime;
    uint256 public s_totalContribution;
    uint256 public s_cycleContribution;
    uint256 public s_upkeepId;
    address[] public s_members;
    address[] public s_remainingWinners;
    bool public s_hasEnded;
    mapping(address => bool) public s_isMember;
    mapping(address => uint256) public s_totalContributionPerMember;
    mapping(address => uint256) public s_cycleContributionPerMember;
    mapping(address => uint256) public s_cycleDistributionPerMember;
    mapping(address => bool) public s_hasWithdrawn;

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
        address uniswapRouter;
        address weth;
    }

    //--------- Events ---------//
    /**
     * @notice Emitted when a member successfully contributes.
     * @param member Address of the contributing member.
     * @param contributionAmount The contributed amount.
     */
    event ContributionDeposited(address indexed member, uint256 contributionAmount);

    /**
     * @notice Emitted when a member withdraws their winnings.
     * @param member Address of the withdrawing member.
     * @param shareAmount The withdrawn amount.
     */
    event ShareWithdrawn(address indexed member, uint256 shareAmount);

    /**
     * @notice Emitted when a winner is selected for a cycle.
     * @param winner Address of the winning member.
     */
    event WinnerPicked(address indexed winner);
    event FundsDeposited(address indexed funder, uint256 totalAmount, uint256 entropyAmount, uint256 linkAmount);
    event UpkeepFunded(uint256 indexed upkeepId, uint256 linkAmount);
    event UpkeepRegistered(uint256 indexed s_upkeepId);

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
        i_totalCycles = config.members.length;
        i_link = LinkTokenInterface(contracts.link);
        i_registrar = IAutomationRegistrar(contracts.registrar);
        i_registry = IAutomationRegistry(contracts.registry);
        i_uniswapRouter = IUniswapV2Router(contracts.uniswapRouter);
        i_weth = contracts.weth;

        //--------- State Variable Assignments ---------//
        s_lastDistributionTime = block.timestamp;
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

    /**
     * @notice Allows anyone to deposit ETH to fund both Pyth Entropy and Chainlink Automation
     * @param _entropyFeePercentage Percentage (0-100) of ETH to keep for Entropy fees
     * @dev Remaining ETH is converted to LINK for automation funding
     */
    /*function fundAutomation(uint256 _entropyFeePercentage) external payable {
        if (msg.value == 0) {
            revert Committee__InsufficientFunding();
        }
        if (_entropyFeePercentage > 100) {
            revert Committee__InvalidPercentage();
        }

        // Calculate split
        uint256 entropyAmount = (msg.value * _entropyFeePercentage) / 100;
        uint256 linkEthAmount = msg.value - entropyAmount;

        // Convert ETH to LINK and register/fund upkeep
        if (s_upkeepId == 0) {
            // First funding - register upkeep
            uint256 linkAmount = _swapEthForLink(linkEthAmount);
            _registerUpkeep(uint96(linkAmount));
        } else {
            // Subsequent funding - add to existing upkeep
            uint256 linkAmount = _swapEthForLink(linkEthAmount);
            if (linkAmount == 0) {
                revert Committee__SwapFailed();
            }
            _addFundsToUpkeep(uint96(linkAmount));
        }

        emit FundsDeposited(msg.sender, msg.value, entropyAmount, linkEthAmount);
    }*/

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
     * @notice Swaps ETH for LINK tokens via Uniswap V2
     * @param _ethAmount Amount of ETH to swap
     * @return linkAmount Amount of LINK received
     */
    /*function _swapEthForLink(uint256 _ethAmount) private returns (uint256 linkAmount) {
        if (_ethAmount == 0) return 0;

        address[] memory path = new address[](2);
        path[0] = i_weth;
        path[1] = address(i_link);

        // Get expected output
        uint256[] memory amountsOut = i_uniswapRouter.getAmountsOut(_ethAmount, path);
        uint256 expectedLink = amountsOut[1];

        // Apply 2% slippage tolerance
        uint256 minLinkOut = (expectedLink * 98) / 100;

        // Perform swap
        uint256[] memory amounts = i_uniswapRouter.swapExactETHForTokens{value: _ethAmount}(
            minLinkOut, path, address(this), block.timestamp + 300
        );

        linkAmount = amounts[1];
        return linkAmount;
    }*/

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
            gasLimit: 500000,
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
        if (s_cycleContributionPerMember[msg.sender] != 0) {
            revert Committee__WaitForNextCycleToStart();
        }

        //--------- Effects ---------//
        s_totalContributionPerMember[msg.sender] += i_contributionAmount;
        s_cycleContributionPerMember[msg.sender] = i_contributionAmount;
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
     * @notice Internal helper that checks if the distribution interval has passed.
     * @return True if its time to select a winner and new distribution cycle to start.
     */
    function _isDistributionTime() private view returns (bool) {
        return block.timestamp >= s_lastDistributionTime + i_distributionInterval;
    }

    function checkUpkeep(bytes memory /* checkData */ )
        public
        view
        override
        returns (bool upkeepNeeded, bytes memory /* performData */ )
    {
        bool isDistributionTime = _isDistributionTime();
        bool hasEveryoneContributed = s_cycleContribution == (s_members.length * i_contributionAmount);
        bool cycleHasNotEnded = s_currentCycle < i_totalCycles;
        upkeepNeeded = (isDistributionTime && hasEveryoneContributed && cycleHasNotEnded && !s_hasEnded);
        return (upkeepNeeded, "0x0");
    }

    function performUpkeep(bytes calldata /* performData */ ) external override {
        (bool upkeepNeeded,) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Committee__UpkeepNotNeeded();
        }

        if (s_remainingWinners.length > 1) {
            uint128 requestFee = i_entropy.getFeeV2();
            if (address(this).balance < requestFee) {
                revert Committee__InsufficientFundsForRequest();
            }
            uint64 sequenceNumber = i_entropy.requestV2{value: requestFee}();
        } else {
            s_lastDistributionTime += i_collectionInterval;
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
            s_hasEnded = true;
        }
    }

    function entropyCallback(uint64 sequenceNumber, address _providerAddress, bytes32 randomNumber) internal override {
        {
            s_lastDistributionTime += i_collectionInterval;
            s_currentCycle += 1;
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
    }

    function getEntropy() internal view override returns (address) {
        return address(i_entropy);
    }

    /**
     * @notice Allows anyone to send ETH to fund randomness fees.
     */
    function fundEntropy() external payable {}

    /**
     * @notice Returns current upkeep balance
     */
    function getUpkeepBalance() external view returns (uint96) {
        if (s_upkeepId == 0) return 0;
        return i_registry.getUpkeep(s_upkeepId).balance;
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
     * @notice Withdraws all ETH held by the contract to the owner.
     */
    function withdrawEth() external onlyOwner {
        (bool success,) = payable(owner()).call{value: address(this).balance}("");
        if (!success) {
            revert Committee__EthTransferFailed();
        }
    }

    /**
     * @notice Get upkeep ID for this committee
     */
    function getUpkeepId() external view returns (uint256) {
        return s_upkeepId;
    }

    /**
     * @notice Get expected LINK output for ETH amount
     */
    function getExpectedLinkOutput(uint256 _ethAmount) external view returns (uint256) {
        if (_ethAmount == 0) return 0;

        address[] memory path = new address[](2);
        path[0] = i_weth;
        path[1] = address(i_link);

        uint256[] memory amounts = i_uniswapRouter.getAmountsOut(_ethAmount, path);
        return amounts[1];
    }

    receive() external payable {}
}
