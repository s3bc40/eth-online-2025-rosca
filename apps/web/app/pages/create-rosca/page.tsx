"use client";

import Navbar from "../../components/Navbar";
// // ------------ TO REMOVE ------------
// import { useChainId, useReadContract } from "wagmi";
// import CommitteeABI from "@repo/foundry-utils/abis/Committee.json";
// import { getFactoryContractAddress } from "../../utils/helpers";
// // ------------ TO REMOVE ------------

export default function CreateRosca() {
  // // ------------ TO REMOVE ------------
  // const chainId = useChainId();
  // const result = useReadContract({
  //   abi: CommitteeABI,
  //   address: getFactoryContractAddress(chainId),
  //   functionName: "owner",
  // });
  // console.log("owner:", result.data);
  // // ------------ TO REMOVE ------------
  return (
    <div>
      <Navbar />
      <div className="flex flex-col items-center justify-center min-h-screen bg-gray-50">
        <h1 className="text-3xl font-bold text-gray-800">create rosca form </h1>
      </div>
    </div>
  );
}
