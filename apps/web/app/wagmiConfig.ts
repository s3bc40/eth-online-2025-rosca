"use client";

import "@rainbow-me/rainbowkit/styles.css";
import { getDefaultConfig } from "@rainbow-me/rainbowkit";
import { anvil, arbitrumSepolia } from "wagmi/chains";
import { Config, cookieStorage, createStorage } from "wagmi";

export const config: Config = getDefaultConfig({
  appName: "ROSCA DApp",
  projectId: process.env.NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID!,
  chains:
    process.env.NODE_ENV === "development"
      ? [anvil, arbitrumSepolia]
      : [arbitrumSepolia],
  ssr: true,
  storage: createStorage({
    storage: cookieStorage,
  }),
});
