import { AbiEvent, createPublicClient, createWalletClient, http } from "viem";
import { privateKeyToAccount } from "viem/accounts";
import { anvil } from "viem/chains";
import MockAutonationRegistrarAbi from "./abis/MockAutomationRegistrar.json";
import MockAutomationRegistryAbi from "./abis/MockAutomationRegistry.json";
import MockEntropyAbi from "./abis/MockEntropy.json";

// WARNING: To updated if necessary after new deployments on Anvil (check /apps/foundry/deployments/anvil/)
const MOCK_ENTROPY_ANVIL = "0x9A9f2CCfdE556A7E9Ff0848998Aa4a0CFD8863AE";
const MOCK_REGISTRAR_ANVIL = "0x3Aa5ebB10DC797CAC828524e59A333d0A371443c";
const MOCK_REGISTRY_ANVIL = "0x68B1D87F95878fE05B998F19b66F4baba5De1aed";

// Setup viem clients
const publicClient = createPublicClient({
  chain: anvil,
  transport: http("http://localhost:8545"),
});

// Anvil 5 account private key
const account = privateKeyToAccount(
  "0x8b3a350cf5c34c9194ca85829a2df0ec3153be0318b5e2d3348e872092edffba"
);

const walletClient = createWalletClient({
  account,
  chain: anvil,
  transport: http("http://localhost:8545"),
});

/**
 * Listen for UpkeepRegistered event and call performUpkeep when detected
 */
async function listenUpkeepRegistered() {
  await publicClient.watchEvent({
    address: MOCK_REGISTRAR_ANVIL,
    event: MockAutonationRegistrarAbi.find(
      (e) => e.name === "UpkeepRegistered"
    ) as AbiEvent,
    // When event is detected make the performUpkeep call
    onLogs: async (logs) => {
      for (const log of logs) {
        const { id: upkeepId } = log.args as {
          id: number;
          performData: string;
        };
        console.log("UpkeepRegistered:", upkeepId);
        // Call performUpkeep
        await walletClient.writeContract({
          address: MOCK_REGISTRY_ANVIL,
          abi: MockAutomationRegistryAbi,
          functionName: "performUpkeep",
          args: [upkeepId, "0x"],
        });
        console.log("performUpkeep called for", upkeepId);
      }
    },
  });
}

/**
 * Listen for RandomNumberRequested event and call fulfillRequest when detected
 */
async function listenRandomNumberRequested() {
  await publicClient.watchEvent({
    address: MOCK_ENTROPY_ANVIL,
    event: MockEntropyAbi.find(
      (e) => e.name === "RandomNumberRequested"
    ) as AbiEvent,
    // When event is detected make the fulfillRequest call
    onLogs: async (logs) => {
      for (const log of logs) {
        const { sequenceNumber } = log.args as { sequenceNumber: number };
        console.log("RandomNumberRequested:", sequenceNumber);
        // Call fulfillRequest
        await walletClient.writeContract({
          address: MOCK_ENTROPY_ANVIL,
          abi: MockEntropyAbi,
          functionName: "fulfillRequest",
          args: [sequenceNumber, "0x"],
        });
        console.log("fulfillRequest called for", sequenceNumber);
      }
    },
  });
}

/**
 * Main function to start the oracle mock listeners
 */
async function main() {
  console.log("Starting viem oracle mock...");
  listenUpkeepRegistered();
  listenRandomNumberRequested();
  console.log("Viem oracle mock is listening for events!");
}

main();
