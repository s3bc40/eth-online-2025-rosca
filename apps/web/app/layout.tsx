import type { Metadata } from "next";
import { headers } from "next/headers";
import { cookieToInitialState } from "wagmi";
import "./globals.css";
import Providers from "./providers";
import { config } from "./wagmiConfig";

export const metadata: Metadata = {
  title: "ROSCA DApp",
  description:
    "A Decentralized Application for Rotating Savings and Credit Associations (ROSCAs) built with Next.js, RainbowKit, and Wagmi",
};

export default async function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  const initialState = cookieToInitialState(
    config,
    (await headers()).get("cookie")
  );
  return (
    <html lang="en">
      <body>
        <Providers initialState={initialState}>{children}</Providers>
      </body>
    </html>
  );
}
