"use client";

import "@rainbow-me/rainbowkit/styles.css";
import { getDefaultConfig } from "@rainbow-me/rainbowkit";
import { sepolia, mainnet, anvil, arbitrumSepolia } from "wagmi/chains";
import { Config, cookieStorage, createStorage } from "wagmi";

export const config: Config = getDefaultConfig({
  appName: "ROSCA DApp",
  projectId: process.env.NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID!,
  chains: [anvil, arbitrumSepolia, sepolia, mainnet],
  ssr: true,
  storage: createStorage({
    storage: cookieStorage,
  }),
});
