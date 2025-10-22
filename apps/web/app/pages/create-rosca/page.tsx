"use client";
import { useState } from "react";
import Navbar from "../../components/Navbar";
// // ------------ TO REMOVE ------------
// import { useChainId, useReadContract } from "wagmi";
// import CommitteeABI from "@repo/foundry-utils/abis/Committee.json";
// import { getFactoryContractAddress } from "../../utils/helpers";
// // ------------ TO REMOVE ------------

export default function CreateRosca() {
  const [roscaName, setRoscaName] = useState("");
  const [contribution, setContribution] = useState("");
  const [cycleDuration, setCycleDuration] = useState("");
  const [requiredSignatures, setRequiredSignatures] = useState("");
  const [members, setMembers] = useState([""]);
  
  // Update member address
  const updateMember = (index, value) => {
    const newMembers = [...members];
    newMembers[index] = value;
    setMembers(newMembers);
  };
  
  // Delete member
  const deleteMember = (index) => {
    const newMembers = members.filter((_, i) => i !== index);
    setMembers(newMembers);
  };
  
  // Add new member
  const addMember = () => {
    setMembers([...members, ""]);
  };
    // later → call your smart contract createRosca()
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
      {/* <div className="flex flex-col items-center justify-center min-h-screen bg-gray-50">
        <h1 className="text-3xl font-bold text-gray-800">create rosca form </h1>
      </div> */}
      <div className="flex flex-col items-center min-h-screen bg-gray-50 px-12 py-8">
      {/* Header */}
      <div className="flex flex-col items-start mb-8">
        <h1 className="text-3xl font-bold text-gray-800 mb-4">Create ROSCA Form</h1>
      </div>

      {/* Form container */}
      <div className="flex flex-col space-y-8 w-full max-w-2xl">
        {/* 1. Basic Information */}
        <div className="flex flex-col space-y-4 border p-6 rounded-md shadow-sm">
          <div className="flex items-center space-x-2">
            <span>👤</span>
            <h2 className="text-xl font-medium text-gray-800">Basic Information</h2>
          </div>
          <input
            type="text"
            placeholder="ROSCA Name*"
            className="border rounded p-2 w-full text-gray-800"
            value={roscaName}
            onChange={(e) => setRoscaName(e.target.value)}
          />
          <input
            type="number"
            placeholder="$ Contribution Amount (PYUSD per round)"
            className="border rounded p-2 w-full text-gray-800"
            value={contribution}
            onChange={(e) => setContribution(e.target.value)}
          />
          <input
            type="number"
            placeholder="Cycle Duration (days)"
            className="border rounded p-2 w-full text-gray-800"
            value={cycleDuration}
            onChange={(e) => setCycleDuration(e.target.value)}
          />
        </div>

        {/* 2. Multi-Signature Security */}
        <div className="flex flex-col space-y-4 border p-6 rounded-md shadow-sm">
          <div className="flex items-center space-x-2">
            <span>🛡️</span>
            <h2 className="text-xl font-medium text-gray-800">Multi-Signature Security</h2>
          </div>
          <input
            type="number"
            placeholder="Required Signatures for Payout*"
            className="border rounded p-2 w-full text-gray-800"
            value={requiredSignatures}
            onChange={(e) => setRequiredSignatures(e.target.value)}
          />
          
          {/* Members */}
          <div className="flex flex-col space-y-2 mt-4">
            <h3 className="text-gray-700 text-sm font-normal">Members</h3>
            {members.map((member, index) => (
              <div key={index} className="flex items-center space-x-2">
                <input
                  type="text"
                  placeholder="Member address"
                  className="border rounded p-2 flex-1 text-gray-800"
                  value={member}
                  onChange={(e) => updateMember(index, e.target.value)}
                />
                <button onClick={() => deleteMember(index)} className="text-red-500">
                  <span>🗑️</span>
                </button>
              </div>
            ))}
            <button
              onClick={addMember}
              className="mt-2 text-blue-600 font-medium hover:underline"
            >
              + Add Member
            </button>
          </div>
        </div>

        {/* 3. Summary */}
        <div className="flex flex-col space-y-2 border p-6 rounded-md shadow-sm">
          <h2 className="text-xl font-medium text-gray-800">Summary</h2>
          <p className="text-gray-800"><strong>ROSCA Name:</strong> {roscaName}</p>
          <p className="text-gray-800"><strong>Contribution Amount:</strong> {contribution}</p>
          <p className="text-gray-800"><strong>Cycle Duration:</strong> {cycleDuration}</p>
          <p className="text-gray-800"><strong>Required Signatures:</strong> {requiredSignatures}</p>
          <p className="text-gray-800"><strong>Members:</strong> {members.filter(Boolean).join(", ")}</p>
        </div>

        {/* 4. Create ROSCA Button */}
        <div className="flex justify-center">
          <button className="bg-blue-600 text-white px-6 py-3 rounded-md hover:bg-blue-700">
            Create ROSCA
          </button>
        </div>
      </div>
    </div>
    </div>
  );
}
