"use client";

// import { useEffect, useState } from "react";
// import useSafeProtocolKit from "../../hooks/useSafeProtocolKit";
import { Text } from "../../common/Title";
import Navbar from "../../components/Navbar";

export default function RoscaList() {
  // // ------------ TO REMOVE ------------
  // const { safeKit, initSafeProtocolKit } = useSafeProtocolKit();
  // const [safeAddress, setSafeAddress] = useState<string | undefined>();
  // const [isDeployed, setIsDeployed] = useState<boolean | undefined>();

  // useEffect(() => {
  //   initSafeProtocolKit(
  //     [
  //       "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",
  //       "0x70997970C51812dc3A010C7d01b50e0d17dc79C8",
  //     ],
  //     2
  //   );
  // }, [initSafeProtocolKit]);

  // useEffect(() => {
  //   if (!safeKit) return;
  //   (async () => {
  //     setSafeAddress(await safeKit.getAddress());
  //     setIsDeployed(await safeKit.isSafeDeployed());
  //   })();
  // }, [safeKit]);
  // // ------------ TO REMOVE ------------

  return (
    <div>
      <Navbar />
      <div className="flex flex-col items-center justify-center min-h-screen bg-gray-50">
        <h1 className="text-3xl font-bold text-gray-800">Rosca List</h1>
        <p className="mt-4 text-gray-600">Here are your Rosca groups.</p>
        <Text text="Rosca List" type="h1" />
        <Text text="Rosca List" type="h2" />
        <Text text="Rosca List" type="h3" />
        <Text text="Rosca List" type="label" />
        <Text text="Rosca List" type="pxs" />
        <Text text="Rosca List" type="psm" />
        {/* // ------------ TO REMOVE ------------ */}
        {/* <p className="mt-10 text-orange-800">TEST SAFE KIT</p> */}
        {/* <p className="mt-4 text-orange-600">{safeAddress}</p> */}
        {/* <p className="mt-4 text-orange-600">{String(isDeployed)}</p> */}
        {/* // ------------ TO REMOVE ------------ */}
      </div>
    </div>
  );
}
