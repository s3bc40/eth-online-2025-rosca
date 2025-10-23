// Script para enviar ETH en Anvil usando solo viem
import { privateKeyToAccount } from "viem/accounts";
import {
  createPublicClient,
  createWalletClient,
  parseEther,
  formatEther,
  http,
} from "viem";

// Definir la chain de Anvil manualmente
const anvilChain = {
  id: 31337,
  name: "Anvil",
  network: "anvil",
  nativeCurrency: {
    name: "Ether",
    symbol: "ETH",
    decimals: 18,
  },
  rpcUrls: {
    default: {
      http: ["http://localhost:8545"],
    },
    public: {
      http: ["http://localhost:8545"],
    },
  },
};

async function sendETH() {
  const privateKey = "Anvil private key";
  const toAddress = "YOUR_ADDRESS";
  const amount = "1.5";

  try {
    const account = privateKeyToAccount(privateKey);

    const publicClient = createPublicClient({
      chain: anvilChain,
      transport: http("http://localhost:8545"),
    });

    const walletClient = createWalletClient({
      account,
      chain: anvilChain,
      transport: http("http://localhost:8545"),
    });

    console.log("Sender address:", account.address);
    console.log("Sended", amount, "ETH to", toAddress);

    // Verificar balance antes
    const balanceBefore = await publicClient.getBalance({
      address: account.address,
    });
    console.log("Balance before:", formatEther(balanceBefore), "ETH");

    const hash = await walletClient.sendTransaction({
      to: toAddress,
      value: parseEther(amount),
    });

    console.log("Hash  transaction:", hash);
    console.log("waiting for confirmation...");

    const receipt = await publicClient.waitForTransactionReceipt({ hash });
    console.log("✅ confirmed in block:", receipt.blockNumber);

    // Verificar balance después
    const balanceAfter = await publicClient.getBalance({
      address: account.address,
    });
    console.log("balance after:", formatEther(balanceAfter), "ETH");
  } catch (error) {
    console.error("❌ Error:", error.message);
  }
}

sendETH();
