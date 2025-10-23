"use client";

import Safe, {
  ContractNetworksConfig,
  PredictedSafeProps,
  SafeAccountConfig,
  SafeDeploymentConfig,
} from "@safe-global/protocol-kit";
import { Eip1193Provider } from "@safe-global/protocol-kit";
import { useState } from "react";
import { useAccount, useChains } from "wagmi";
import anvilSafeContracts from "@repo/anvil-states/safe-contracts.json";
import { Chain } from "viem";
import {
  getCreateCallDeployment,
  getFallbackHandlerDeployment,
  getMultiSendCallOnlyDeployment,
  getMultiSendDeployment,
  getProxyFactoryDeployment,
  getSafeSingletonDeployment,
  getSignMessageLibDeployment,
  getSimulateTxAccessorDeployment,
} from "@safe-global/safe-deployments";

const SAFE_VERSION = "1.4.1";

/**
 * Function to get Anvil contract networks configuration
 *
 */
function anvilContractNetworks() {
  return {
    safeSingletonAddress: anvilSafeContracts.contracts.Safe,
    safeProxyFactoryAddress: anvilSafeContracts.contracts.SafeProxyFactory,
    multiSendAddress: anvilSafeContracts.contracts.MultiSend,
    multiSendCallOnlyAddress: anvilSafeContracts.contracts.MultiSendCallOnly,
    fallbackHandlerAddress:
      anvilSafeContracts.contracts.CompatibilityFallbackHandler,
    signMessageLibAddress: anvilSafeContracts.contracts.SignMessageLib,
    createCallAddress: anvilSafeContracts.contracts.CreateCall,
    simulateTxAccessorAddress: anvilSafeContracts.contracts.SimulateTxAccessor,
  };
}

/**
 * Function to get contract networks configuration based on supported chains
 *
 * @param chains - Array of supported chains
 * @returns ContractNetworksConfig object
 */
function getContractNetworks(chains: readonly Chain[]) {
  // Define contract networks configuration
  const contractNetworks: ContractNetworksConfig = {};
  for (const chain of chains) {
    if (chain.id === 31337) {
      // Anvil chain ID
      contractNetworks[chain.id] = anvilContractNetworks();
    } else {
      // For other supported networks, fetch addresses from safe-deployments
      contractNetworks[chain.id] = {
        safeSingletonAddress: getSafeSingletonDeployment({
          version: SAFE_VERSION,
          network: chain.id.toString(),
        })?.defaultAddress,
        safeProxyFactoryAddress: getProxyFactoryDeployment({
          version: SAFE_VERSION,
          network: chain.id.toString(),
        })?.defaultAddress,
        multiSendAddress: getMultiSendDeployment({
          version: SAFE_VERSION,
          network: chain.id.toString(),
        })?.defaultAddress,
        multiSendCallOnlyAddress: getMultiSendCallOnlyDeployment({
          version: SAFE_VERSION,
          network: chain.id.toString(),
        })?.defaultAddress,
        fallbackHandlerAddress: getFallbackHandlerDeployment({
          version: SAFE_VERSION,
          network: chain.id.toString(),
        })?.defaultAddress,
        signMessageLibAddress: getSignMessageLibDeployment({
          version: SAFE_VERSION,
          network: chain.id.toString(),
        })?.defaultAddress,
        createCallAddress: getCreateCallDeployment({
          version: SAFE_VERSION,
          network: chain.id.toString(),
        })?.defaultAddress,
        simulateTxAccessorAddress: getSimulateTxAccessorDeployment({
          version: SAFE_VERSION,
          network: chain.id.toString(),
        })?.defaultAddress,
      };
    }
  }
  return contractNetworks;
}

/**
 * Custom hook to initialize and manage Safe Protocol Kit instance
 */
export default function useSafeProtocolKit() {
  // Init wagmi provider and signer here
  const { address, connector, isConnected } = useAccount();
  const chains = useChains();

  // State to hold the Safe Protocol Kit instance
  const [safeKit, setSafeKit] = useState<Safe | null>(null);

  /**
   * Initialize Safe Protocol Kit from owners and threshold
   *
   * @param owners - Array of owner addresses
   * @param threshold - Number of required confirmations
   *
   * Set the Safe Protocol Kit instance in state
   */
  async function initSafeProtocolKit(
    owners: `0x${string}`[],
    threshold: number
  ) {
    if (!isConnected) return;
    const provider = await connector?.getProvider();
    const signer = address;

    if (!provider) {
      throw new Error("Provider not available");
    }

    // Setup Safe account configuration
    const safeAccountConfig: SafeAccountConfig = {
      owners,
      threshold,
    };

    // Define deployment configuration (ensure safe version 1.4.1)
    const safeDeploymentConfig: SafeDeploymentConfig = {
      safeVersion: "1.4.1",
      deploymentType: "canonical",
    };

    // Init predicted safe props
    const predictedSafe: PredictedSafeProps = {
      safeAccountConfig,
      safeDeploymentConfig,
    };

    // Get protocol kit instance
    const protocolKit = await Safe.init({
      provider: provider as Eip1193Provider, // force Wagmi provider type
      signer,
      predictedSafe,
      contractNetworks: getContractNetworks(chains),
    });

    setSafeKit(protocolKit);
  }

  return { safeKit, initSafeProtocolKit };
}
