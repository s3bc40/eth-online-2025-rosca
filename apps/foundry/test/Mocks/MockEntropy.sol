// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

// ===========================================
// Mock Pyth Entropy
// ===========================================

import {IEntropyConsumer} from "@pythnetwork/entropy-sdk-solidity/IEntropyConsumer.sol";

contract MockEntropy {
    uint128 private constant DEFAULT_FEE = 0.001 ether;
    uint64 private sequenceCounter;
    address private defaultProvider;

    struct PendingRequest {
        address requester;
        address provider;
        bool exists;
    }

    mapping(uint64 => PendingRequest) public pendingRequests;

    event RandomNumberRequested(uint64 indexed sequenceNumber, address indexed requester, address indexed provider);

    event RandomNumberRevealed(uint64 indexed sequenceNumber, address indexed requester, bytes32 randomNumber);

    constructor() {
        defaultProvider = address(this);
    }

    function setDefaultProvider(address provider) external {
        defaultProvider = provider;
    }

    function getDefaultProvider() external view returns (address) {
        return defaultProvider;
    }

    function getFeeV2() external pure returns (uint128) {
        return DEFAULT_FEE;
    }

    function getFee(address /* provider */ ) external pure returns (uint128) {
        return DEFAULT_FEE;
    }

    function requestV2() external payable returns (uint64) {
        require(msg.value >= DEFAULT_FEE, "Insufficient fee");

        uint64 sequenceNumber = ++sequenceCounter;

        pendingRequests[sequenceNumber] =
            PendingRequest({requester: msg.sender, provider: defaultProvider, exists: true});

        emit RandomNumberRequested(sequenceNumber, msg.sender, defaultProvider);

        return sequenceNumber;
    }

    function request(address provider, bytes32, /* userCommitment */ bool /* useBlockhash */ )
        external
        payable
        returns (uint64)
    {
        require(msg.value >= DEFAULT_FEE, "Insufficient fee");

        uint64 sequenceNumber = ++sequenceCounter;

        pendingRequests[sequenceNumber] = PendingRequest({requester: msg.sender, provider: provider, exists: true});

        emit RandomNumberRequested(sequenceNumber, msg.sender, provider);

        return sequenceNumber;
    }

    function reveal(
        address, /* provider */
        uint64, /* sequenceNumber */
        bytes32, /* userRandomness */
        bytes32 /* providerRevelation */
    ) external pure returns (bytes32) {
        // Mock implementation - not used in our tests
        return bytes32(0);
    }

    function revealWithCallback(
        address, /* provider */
        uint64, /* sequenceNumber */
        bytes32, /* userRandomness */
        bytes32 /* providerRevelation */
    ) external pure {
        // Mock implementation - not used in our tests
        revert("Use fulfillRequest instead");
    }

    // Simulate callback - in real scenario this would be called by keeper
    function fulfillRequest(uint64 sequenceNumber, bytes32 providerRevelation) external {
        PendingRequest memory req = pendingRequests[sequenceNumber];
        require(req.exists, "Request does not exist");

        // Generate pseudo-random number
        bytes32 randomNumber =
            keccak256(abi.encodePacked(block.timestamp, block.prevrandao, sequenceNumber, providerRevelation));

        // Call _entropyCallback on requester if it's a contract
        if (req.requester.code.length > 0) {
            try IEntropyConsumer(req.requester)._entropyCallback(sequenceNumber, req.provider, randomNumber) {} catch {}
        }

        delete pendingRequests[sequenceNumber];

        emit RandomNumberRevealed(sequenceNumber, req.requester, randomNumber);
    }

    // Helper for testing - auto-fulfill after a delay
    function requestAndFulfill(bytes32 userRandomNumber) external payable returns (bytes32) {
        uint64 seqNum = this.requestV2{value: msg.value}();
        bytes32 randomNumber = keccak256(abi.encodePacked(block.timestamp, block.prevrandao, seqNum, userRandomNumber));

        PendingRequest memory req = pendingRequests[seqNum];
        if (req.requester.code.length > 0) {
            try IEntropyConsumer(req.requester)._entropyCallback(seqNum, req.provider, randomNumber) {} catch {}
        }

        delete pendingRequests[seqNum];
        return randomNumber;
    }

    receive() external payable {}
}
