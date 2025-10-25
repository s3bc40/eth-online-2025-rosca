"use client";
import { useEffect, useState } from "react";
import Navbar from "../../components/Navbar";
import SafeSetupPage from "../../components/MultisigWallet/MultisigWallet";
import {
  useAccount,
  useChainId,
  useWriteContract,
  useWaitForTransactionReceipt,
} from "wagmi";
import FactoryABI from "@repo/foundry-utils/abis/Factory.json";
import { getFactoryContractAddress } from "../../utils/helpers";
import { parseUnits } from "viem";
import {
  Users,
  DollarSign,
  Shield,
  ArrowLeft,
  PlusCircle,
  Trash2,
} from "lucide-react";
import Link from "next/link";
import { Text } from "../../common/Title";
import useSafeProtocolKit from "../../hooks/useSafeProtocolKit";
import { useMultisigAddresses } from "../../hooks/useMultisigAddresses";
export default function CreateRosca() {
  // Constants
  const MINIMAL_MEMBERS = 5;
  const MEMBERS_SAFE_THRESHOLD = 3;

  // State variables
  const [roscaName, setRoscaName] = useState("");
  const [contribution, setContribution] = useState("");
  const [cycleDuration, setCycleDuration] = useState("");
  const [requiredSignatures, setRequiredSignatures] = useState("");
  const [members, setMembers] = useState([""]);
  const [multiSigAddress, setMultiSigAddress] = useState("");
  const [open, setOpen] = useState(false);

  // Wagmi hooks
  const chainId = useChainId();
  const { address } = useAccount();
  const { writeContract, data: hash, isPending, error } = useWriteContract();
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({
    hash,
  });

  // @DEV -> to remove later, it's an example
  // SafeKit hook
  // const { initSafeProtocolKit, safeKit } = useSafeProtocolKit();

  // useEffect(() => {
  //   const actualMembers = members.filter((m) => m.trim() !== "");
  //   if (actualMembers.length < MINIMAL_MEMBERS) return;
  //   // Initialize Safe Protocol Kit when multiSigAddress or members change
  //   const initializeKit = async () => {
  //     initSafeProtocolKit(
  //       actualMembers as `0x${string}`[],
  //       MEMBERS_SAFE_THRESHOLD
  //     );
  //     setMultiSigAddress((await safeKit?.getAddress()) || "");
  //   };

  //   initializeKit();
  // }, [members, initSafeProtocolKit, safeKit, setMultiSigAddress]);
  // @DEV -> to remove later, it's an example

  // Multisig addresses hook
  const { addAddressLocalStorage } = useMultisigAddresses();

  // Update member address
  const updateMember = (index: number, value: string) => {
    const newMembers = [...members];
    newMembers[index] = value;
    setMembers(newMembers);
  };

  // Delete member
  const deleteMember = (index: number) => {
    const newMembers = members.filter((_, i) => i !== index);
    setMembers(newMembers);
  };

  // Add new member
  const addMember = () => {
    setMembers([...members, ""]);
  };

  // Create ROSCA function
  const handleCreateRosca = async () => {
    try {
      const factoryAddress = getFactoryContractAddress(chainId);
      if (!factoryAddress) {
        alert("Factory contract not found for this network");
        return;
      }

      // Validate inputs
      if (!contribution || !cycleDuration || !multiSigAddress) {
        alert("Please fill in all required fields");
        return;
      }

      const validMembers = members.filter((m) => m.trim() !== "");
      if (validMembers.length === 0) {
        alert("Please add at least one member");
        return;
      }

      // Convert contribution amount to wei (PYUSD has 6 decimals)
      const contributionAmount = parseUnits(contribution, 6);

      // Convert cycle duration from days to seconds
      const collectionInterval = BigInt(Number(cycleDuration) * 24 * 60 * 60);
      const distributionInterval = collectionInterval; // Same as collection for now

      // Call the createCommittee function
      writeContract({
        address: factoryAddress,
        abi: FactoryABI,
        functionName: "createCommittee",
        args: [
          contributionAmount,
          collectionInterval,
          distributionInterval,
          validMembers as `0x${string}`[],
          multiSigAddress as `0x${string}`,
        ],
      });
      // Store the multisig address locally
      addAddressLocalStorage(multiSigAddress);
    } catch (err) {
      console.error("Error creating ROSCA:", err);
      alert("Failed to create ROSCA");
    }
  };
  const totalMembers = members.filter((m) => m.trim()).length;

  return (
    <div>
      <Navbar />
      <div className="min-h-screen py-12">
        <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="card">
            <Text text="Create New ROSCA" type="h1" />
            <br />
            <div className="border-b border-gray-200 dark:border-slate-700 pb-6 mb-6"></div>
            <br />
            <form
              onSubmit={(e) => {
                e.preventDefault();
                handleCreateRosca();
              }}
              className="space-y-8"
            >
              {/* Basic Information */}
              <div>
                <h2 className="text-xl font-semibold text-gray-900 dark:text-slate-100 mb-4 flex items-center">
                  <Users className="h-6 w-6 mr-2 text-primary-600 dark:text-primary-400" />
                  Basic Information
                </h2>
                <div className="space-y-4">
                  <div>
                    <label
                      htmlFor="name"
                      className="block text-sm font-medium text-gray-700 dark:text-slate-300 mb-1"
                    >
                      ROSCA Name
                    </label>
                    <input
                      type="text"
                      id="name"
                      name="name"
                      required
                      value={roscaName}
                      onChange={(e) => setRoscaName(e.target.value)}
                      className="w-full px-4 py-2 border border-gray-300 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-700 text-gray-900 dark:text-slate-100 placeholder-gray-400 dark:placeholder-slate-500 focus:ring-2 focus:ring-primary-500 focus:border-transparent"
                      placeholder="e.g., Tech Professionals Circle"
                    />
                  </div>
                </div>
              </div>

              {/* Contribution Details */}
              <div>
                <h2 className="text-xl font-semibold text-gray-900 dark:text-slate-100 mb-4 flex items-center">
                  <DollarSign className="h-6 w-6 mr-2 text-secondary-600 dark:text-secondary-400" />
                  Contribution Details
                </h2>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div>
                    <label
                      htmlFor="contributionAmount"
                      className="block text-sm font-medium text-gray-700 dark:text-slate-300 mb-1"
                    >
                      Contribution Amount (PYUSD) *
                    </label>
                    <input
                      type="number"
                      id="contributionAmount"
                      name="contributionAmount"
                      required
                      step="0.01"
                      min="0"
                      value={contribution}
                      onChange={(e) => setContribution(e.target.value)}
                      className="w-full px-4 py-2 border border-gray-300 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-700 text-gray-900 dark:text-slate-100 placeholder-gray-400 dark:placeholder-slate-500 focus:ring-2 focus:ring-primary-500 focus:border-transparent"
                      placeholder="500.00"
                    />
                  </div>

                  <div>
                    <label
                      htmlFor="cycleDuration"
                      className="block text-sm font-medium text-gray-700 dark:text-slate-300 mb-1"
                    >
                      Cycle Duration (days) *
                    </label>
                    <input
                      type="number"
                      id="cycleDuration"
                      name="cycleDuration"
                      required
                      min="1"
                      value={cycleDuration}
                      onChange={(e) => setCycleDuration(e.target.value)}
                      className="w-full px-4 py-2 border border-gray-300 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-700 text-gray-900 dark:text-slate-100 placeholder-gray-400 dark:placeholder-slate-500 focus:ring-2 focus:ring-primary-500 focus:border-transparent"
                      placeholder="30"
                    />
                  </div>
                </div>
              </div>

              {/* Multi-Signature Security */}
              <div>
                <h2 className="text-xl font-semibold text-gray-900 dark:text-slate-100 mb-4 flex items-center">
                  <Shield className="h-6 w-6 mr-2 text-primary-600 dark:text-primary-400" />
                  Multi-Signature Security
                </h2>
                <div className="space-y-4">
                  <div>
                    <p className="text-sm font-medium text-gray-700 dark:text-slate-300 mb-1">
                      Multi-Sig Account Address
                    </p>
                    <div className="px-4 py-2 border border-gray-300 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-700 text-gray-900 dark:text-slate-100 font-mono break-all">
                      {multiSigAddress
                        ? multiSigAddress
                        : "No Safe connected yet"}
                    </div>
                  </div>

                  <button
                    onClick={() => setOpen(true)}
                    className="px-4 py-2 bg-primary-600 hover:bg-primary-700 text-white rounded-lg transition"
                  >
                    {multiSigAddress ? "Change Safe" : "Setup / Connect Safe"}
                  </button>

                  {open && (
                    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-sm">
                      <div className="bg-white dark:bg-slate-800 rounded-2xl p-6 max-w-lg w-full relative">
                        <button
                          onClick={() => setOpen(false)}
                          className="absolute top-3 right-3 text-gray-500 hover:text-gray-800 dark:text-slate-400 dark:hover:text-slate-200"
                        >
                          ✕
                        </button>
                        <SafeSetupPage
                          onSafeConnected={(addr) => {
                            setMultiSigAddress(addr);
                            setOpen(false);
                          }}
                        />
                      </div>
                    </div>
                  )}
                </div>
              </div>

              {/* Members */}
              <div>
                <div className="flex items-center justify-between mb-4">
                  <h2 className="text-xl font-semibold text-gray-900 dark:text-slate-100 flex items-center">
                    <Users className="h-6 w-6 mr-2 text-primary-600 dark:text-primary-400" />
                    Members
                  </h2>
                  <span className="text-sm text-gray-500 dark:text-slate-400 font-medium">
                    {totalMembers} member{totalMembers !== 1 ? "s" : ""}
                  </span>
                </div>
                <div className="bg-gradient-to-br from-primary-50 to-secondary-50 dark:from-primary-950/30 dark:to-secondary-950/30 border-2 border-primary-200 dark:border-primary-800 rounded-lg p-4 mb-4">
                  <div className="flex items-start gap-2">
                    <Shield className="h-5 w-5 text-primary-700 dark:text-primary-300 flex-shrink-0 mt-0.5" />
                    <div>
                      <h3 className="font-bold text-primary-900 dark:text-primary-200 text-sm mb-1">
                        Administrative Multisig
                      </h3>
                      <p className="text-xs text-primary-800 dark:text-primary-300">
                        The multi-sig address you provided will be used for
                        administrative actions (removing defaulted members,
                        restarting ROSCA). Payouts are automatic.
                      </p>
                    </div>
                  </div>
                </div>
                <p className="text-sm text-gray-600 dark:text-slate-400 mb-4">
                  Add members to your ROSCA. Each member must provide a valid
                  wallet address.
                </p>
                <div className="space-y-3">
                  {members.map((member, index) => (
                    <div
                      key={index}
                      className="bg-gray-50 dark:bg-slate-800/50 p-4 rounded-lg border border-gray-200 dark:border-slate-700 hover:border-primary-300 dark:hover:border-primary-700 transition-colors"
                    >
                      <div className="flex gap-3">
                        <div className="flex-shrink-0 w-8 h-8 rounded-full flex items-center justify-center font-semibold text-sm bg-primary-100 dark:bg-primary-900/30 text-primary-700 dark:text-primary-400">
                          {index + 1}
                        </div>
                        <div className="flex-1">
                          <label
                            htmlFor={`wallet-${index}`}
                            className="block text-xs font-medium text-gray-700 dark:text-slate-300 mb-1.5"
                          >
                            Wallet Address *
                          </label>
                          <input
                            type="text"
                            id={`wallet-${index}`}
                            value={member}
                            onChange={(e) =>
                              updateMember(index, e.target.value)
                            }
                            required
                            className="w-full px-3 py-2 border border-gray-300 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-700 text-gray-900 dark:text-slate-100 placeholder-gray-400 dark:placeholder-slate-500 focus:ring-2 focus:ring-primary-500 focus:border-transparent text-sm font-mono"
                            placeholder="0x..."
                          />
                        </div>
                        {members.length > 1 && (
                          <button
                            type="button"
                            onClick={() => deleteMember(index)}
                            className="flex-shrink-0 h-8 w-8 flex items-center justify-center text-red-600 dark:text-red-400 hover:bg-red-50 dark:hover:bg-red-900/20 rounded-lg transition-colors"
                            title="Remove member"
                          >
                            <Trash2 className="h-4 w-4" />
                          </button>
                        )}
                      </div>
                    </div>
                  ))}
                  <br />
                  <button
                    type="button"
                    onClick={addMember}
                    className="w-full py-3 px-4 border-2 border-dashed border-gray-300 dark:border-slate-600 rounded-lg text-primary-600 dark:text-primary-400 hover:border-primary-400 dark:hover:border-primary-500 hover:bg-primary-50 dark:hover:bg-primary-900/10 font-medium transition-colors flex items-center justify-center"
                  >
                    <PlusCircle className="h-5 w-5 mr-2" />
                    Add Another Member
                  </button>
                </div>
              </div>

              {/* Summary */}
              <div className="bg-gradient-to-br from-primary-50 via-secondary-50 to-accent-50 dark:from-primary-950/30 dark:via-secondary-950/30 dark:to-accent-950/30 p-6 rounded-xl border-2 border-primary-200 dark:border-primary-800 shadow-md">
                <h3 className="font-bold text-gray-900 dark:text-slate-100 mb-4 text-lg">
                  Summary
                </h3>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm">
                  <div className="flex items-center justify-between p-3 bg-white/50 dark:bg-slate-800/30 rounded-lg">
                    <span className="text-gray-600 dark:text-slate-400 mr-2">
                      Total Pool per Round:
                    </span>
                    <span className="font-semibold text-gray-900 dark:text-slate-100">
                      {contribution && totalMembers
                        ? `$${(parseFloat(contribution) * totalMembers).toFixed(2)} PYUSD`
                        : "- PYUSD"}
                    </span>
                  </div>
                  <div className="flex items-center justify-between p-3 bg-white/50 dark:bg-slate-800/30 rounded-lg">
                    <span className="text-gray-600 dark:text-slate-400 mr-2">
                      Total Members (Rounds):
                    </span>
                    <span className="font-semibold text-gray-900 dark:text-slate-100">
                      {totalMembers > 0 ? totalMembers : "-"}
                    </span>
                  </div>
                  <div className="flex items-center justify-between p-3 bg-white/50 dark:bg-slate-800/30 rounded-lg">
                    <span className="text-gray-600 dark:text-slate-400 mr-2">
                      Cycle Duration:
                    </span>
                    <span className="font-semibold text-gray-900 dark:text-slate-100">
                      {cycleDuration
                        ? `${cycleDuration} day${cycleDuration !== "1" ? "s" : ""}`
                        : "-"}
                    </span>
                  </div>
                  <div className="flex items-center justify-between p-3 bg-white/50 dark:bg-slate-800/30 rounded-lg">
                    <span className="text-gray-600 dark:text-slate-400 mr-2">
                      Payout System:
                    </span>
                    <span className="font-semibold text-gray-900 dark:text-slate-100">
                      Automatic
                    </span>
                  </div>
                  <div className="flex items-center justify-between p-3 bg-white/50 dark:bg-slate-800/30 rounded-lg md:col-span-2">
                    <span className="text-gray-600 dark:text-slate-400 mr-2">
                      Admin Control:
                    </span>
                    <span className="font-semibold text-gray-900 dark:text-slate-100">
                      Multisig
                    </span>
                  </div>
                </div>
              </div>

              {/* Submit Button */}
              <div className="flex flex-col space-y-4 pt-6 border-t border-gray-200 dark:border-slate-700">
                <button
                  type="submit"
                  disabled={isPending || isConfirming || !address}
                  className="w-full btn-primary flex items-center justify-center disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  <Shield className="h-5 w-5 mr-2" />
                  {isPending
                    ? "Waiting for approval..."
                    : isConfirming
                      ? "Creating ROSCA..."
                      : "Create ROSCA"}
                </button>

                {/* Transaction Status */}
                {!address && (
                  <p className="text-yellow-600 dark:text-yellow-400 text-sm text-center">
                    Please connect your wallet first
                  </p>
                )}
                {hash && (
                  <p className="text-gray-700 dark:text-slate-300 text-sm text-center">
                    Transaction Hash:{" "}
                    <span className="font-mono">
                      {hash.slice(0, 10)}...{hash.slice(-8)}
                    </span>
                  </p>
                )}
                {isSuccess && (
                  <p className="text-green-600 dark:text-green-400 font-medium text-center">
                    ✅ ROSCA Created Successfully!
                  </p>
                )}
                {error && (
                  <p className="text-red-600 dark:text-red-400 text-sm text-center">
                    Error: {error.message}
                  </p>
                )}
              </div>
            </form>
          </div>
        </div>
      </div>
    </div>
  );
}
