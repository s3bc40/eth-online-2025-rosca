"use client";

import Image, { type ImageProps } from "next/image";

import "./globals.css";

import { useRouter } from "next/navigation";
import { useEffect } from "react";
import { useAccount } from "wagmi";
import { RoscaLogo } from "./common/RoscaLogo";
import ConnectWallet from "./components/ConnectWallet";

type Props = Omit<ImageProps, "src"> & {
  srcLight: string;
  srcDark: string;
};

export default function Home() {
  const { isConnected } = useAccount(); // Check wallet connection status
  const router = useRouter();

  // Redirect to /rosca-list if the wallet is connected
  useEffect(() => {
    if (isConnected) {
      router.push("/pages/my-roscas");
    }
  }, [isConnected, router]);
  return (
    <div className="flex items-center justify-center min-h-screen bg-gray-100">
      <main className="flex flex-col items-center gap-4">
        <RoscaLogo />
        <ConnectWallet />
      </main>
    </div>
  );
}
