// Helpers for the ROSCA DApp
import FactoryAnvil from "../../../foundry/deployments/anvil/Factory.json";
import FacotryArbSepolia from "../../../foundry/deployments/arbitrum-sepolia/Factory.json";

/**
 * Get the factory contract address based on the chain ID
 *
 * @param chainId - The ID of the blockchain network
 * @returns The factory contract address or undefined if not found
 */
export function getFactoryContractAddress(
  chainId: number
): `0x${string}` | undefined {
  const addresses: { [key: number]: `0x${string}` } = {
    31337: FactoryAnvil.address as `0x${string}`, // Anvil
    421613: FacotryArbSepolia.address as `0x${string}`, // Arbitrum Sepolia
  };
  return addresses[chainId];
}
