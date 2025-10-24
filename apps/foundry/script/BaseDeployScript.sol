// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Script, console} from "forge-std/Script.sol";

/**
 * @title BaseDeployScript
 * @notice Base contract for deployment scripts with network detection and utilities
 */
abstract contract BaseDeployScript is Script {
    // Network identifiers
    uint256 constant ARBITRUM_MAINNET = 42161;
    uint256 constant ARBITRUM_SEPOLIA = 421614;
    uint256 constant ANVIL = 31337;

    struct NetworkConfig {
        address pyUsd;
        address entropy;
        address link;
        address registrar;
        address registry;
        address uniswapRouter;
        address weth;
        uint8 maxCommitteeMembers;
    }

    struct DeploymentConfig {
        uint256 chainId;
        string network;
        address deployer;
        NetworkConfig networkConfig;
    }

    DeploymentConfig public config;

    modifier broadcast() {
        uint256 deployerPrivateKey = getDeployerPrivateKey();
        vm.startBroadcast(deployerPrivateKey);
        _;
        vm.stopBroadcast();
    }

    function getDeployerPrivateKey() internal view returns (uint256) {
        if (config.chainId == ARBITRUM_MAINNET || config.chainId == ARBITRUM_SEPOLIA) {
            return vm.envUint("PRIVATE_KEY");
        } else if (config.chainId == ANVIL) {
            // Default Anvil Key
            return 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        }
        revert("Unsupported network");
    }

    function setUp() public virtual {
        config.chainId = block.chainid;
        config.network = getNetworkName(config.chainId);
        config.deployer = vm.addr(getDeployerPrivateKey());
        config.networkConfig = getNetworkConfig(config.chainId);

        console.log("===========================================");
        console.log("Deployment Configuration");
        console.log("===========================================");
        console.log("Network:", config.network);
        console.log("Chain ID:", config.chainId);
        console.log("Deployer:", config.deployer);
        console.log("===========================================");
    }

    function getNetworkName(uint256 chainId) internal pure returns (string memory) {
        if (chainId == ARBITRUM_MAINNET) return "arbitrum";
        if (chainId == ARBITRUM_SEPOLIA) return "arbitrum-sepolia";
        if (chainId == ANVIL) return "anvil";
        return "unknown";
    }

    function getNetworkConfig(uint256 chainId) internal view returns (NetworkConfig memory) {
        if (chainId == ARBITRUM_MAINNET) {
            return getArbitrumMainnetConfig();
        } else if (chainId == ARBITRUM_SEPOLIA) {
            return getArbitrumSepoliaConfig();
        } else if (chainId == ANVIL) {
            return getAnvilConfig();
        }
        revert("Unsupported network");
    }

    function getArbitrumMainnetConfig() internal pure returns (NetworkConfig memory) {
        return NetworkConfig({
            pyUsd: 0x46850aD61C2B7d64d08c9C754F45254596696984,
            entropy: 0x7698E925FfC29655576D0b361D75Af579e20AdAc,
            link: 0xf97f4df75117a78c1A5a0DBb814Af92458539FB4,
            registrar: 0x86EFBD0b6736Bed994962f9797049422A3A8E8Ad,
            registry: 0x37D9dC70bfcd8BC77Ec2858836B923c560E891D1,
            uniswapRouter: 0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24,
            weth: 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1,
            maxCommitteeMembers: 15
        });
    }

    function getArbitrumSepoliaConfig() internal pure returns (NetworkConfig memory) {
        return NetworkConfig({
            pyUsd: 0x637A1259C6afd7E3AdF63993cA7E58BB438aB1B1,
            entropy: 0x549Ebba8036Ab746611B4fFA1423eb0A4Df61440,
            link: 0xb1D4538B4571d411F07960EF2838Ce337FE1E80E,
            registrar: 0x881918E24290084409DaA91979A30e6f0dB52eBe,
            registry: 0x8194399B3f11fcA2E8cCEfc4c9A658c61B8Bf412,
            uniswapRouter: address(0),
            weth: address(0),
            maxCommitteeMembers: 15
        });
    }

    function getAnvilConfig() internal view returns (NetworkConfig memory) {
        // Try to load from deployed mocks first
        address pyUsdAddr = loadDeployment("MockPyUSD");
        address entropyAddr = loadDeployment("MockEntropy");
        address linkAddr = loadDeployment("MockLINK");
        address registrarAddr = loadDeployment("MockRegistrar");
        address registryAddr = loadDeployment("MockRegistry");
        address uniswapAddr = loadDeployment("MockUniswapRouter");
        address wethAddr = loadDeployment("MockWETH");

        // If mocks not deployed, try environment variables
        if (pyUsdAddr == address(0)) {
            pyUsdAddr = vm.envOr("PYUSD_ADDRESS", address(0));
        }
        if (entropyAddr == address(0)) {
            entropyAddr = vm.envOr("ENTROPY_ADDRESS", address(0));
        }
        if (linkAddr == address(0)) {
            linkAddr = vm.envOr("LINK_ADDRESS", address(0));
        }
        if (registrarAddr == address(0)) {
            registrarAddr = vm.envOr("REGISTRAR_ADDRESS", address(0));
        }
        if (registryAddr == address(0)) {
            registryAddr = vm.envOr("REGISTRY_ADDRESS", address(0));
        }
        if (uniswapAddr == address(0)) {
            uniswapAddr = vm.envOr("UNISWAP_ROUTER_ADDRESS", address(0));
        }
        if (wethAddr == address(0)) {
            wethAddr = vm.envOr("WETH_ADDRESS", address(0));
        }

        // If still no addresses, warn user
        if (pyUsdAddr == address(0)) {
            console.log("WARNING: No mock contracts found!");
            console.log("Run: forge script script/DeployMocks.s.sol:DeployMocks --rpc-url $ANVIL_RPC_URL --broadcast");
        }

        return NetworkConfig({
            pyUsd: pyUsdAddr,
            entropy: entropyAddr,
            link: linkAddr,
            registrar: registrarAddr,
            registry: registryAddr,
            uniswapRouter: uniswapAddr,
            weth: wethAddr,
            maxCommitteeMembers: 10
        });
    }

    function isLocalTestnet() internal view returns (bool) {
        return config.chainId == ANVIL;
    }

    function saveDeployment(string memory contractName, address contractAddress) internal {
        console.log("cwd:", vm.projectRoot());
        string memory path = string.concat("deployments/", config.network, "/", contractName, ".json");

        string memory json = string.concat(
            "{\n",
            '  "address": "',
            vm.toString(contractAddress),
            '",\n',
            '  "chainId": ',
            vm.toString(config.chainId),
            ",\n",
            '  "deployer": "',
            vm.toString(config.deployer),
            '",\n',
            '  "timestamp": ',
            vm.toString(block.timestamp),
            ",\n",
            '  "blockNumber": ',
            vm.toString(block.number),
            "\n",
            "}"
        );

        vm.writeJson(json, path);
        console.log("Saved deployment:", contractName);
        console.log("Address:", contractAddress);
        console.log("File:", path);
    }

    function loadDeployment(string memory contractName) internal view returns (address) {
        string memory path = string.concat("deployments/", config.network, "/", contractName, ".json");

        try vm.readFile(path) returns (string memory json) {
            bytes memory data = vm.parseJson(json, ".address");
            address addr = abi.decode(data, (address));
            console.log("Loaded", contractName, "from", path);
            console.log("Address:", addr);
            return addr;
        } catch {
            console.log("No existing deployment found for", contractName);
            return address(0);
        }
    }

    function run() public virtual;
}
