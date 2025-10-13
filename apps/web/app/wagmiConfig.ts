"use client";

import "@rainbow-me/rainbowkit/styles.css";
import { getDefaultConfig } from "@rainbow-me/rainbowkit";
import { sepolia, mainnet, anvil } from "wagmi/chains";
import { Config, cookieStorage, createStorage } from "wagmi";

export const config: Config = getDefaultConfig({
  appName: "ROSCA DApp",
  projectId: process.env.NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID!,
  chains: [sepolia, mainnet, anvil],
  ssr: true,
  storage: createStorage({
    storage: cookieStorage,
  }),
});
