// Helpers for the ROSCA DApp

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
    31337: "0xa85233C63b9Ee964Add6F2cffe00Fd84eb32338f", // Anvil
    11155111: "0xYourSepoliaFactoryAddressHere", // Sepolia
    421613: "0xYourArbitrumSepoliaFactoryAddressHere", // Arbitrum Sepolia
    1: "0xYourMainnetFactoryAddressHere", // Mainnet
  };
  return addresses[chainId];
}
