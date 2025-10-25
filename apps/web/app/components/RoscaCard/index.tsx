"use client";

import { useState, useEffect } from "react";
import { useReadContract, useAccount, useWriteContract, useWatchContractEvent } from "wagmi";
import CommitteeABI from "@repo/foundry-utils/abis/Committee.json";
import { formatUnits } from "viem";
import {
  Users,
  DollarSign,
  Calendar,
  TrendingUp,
  ExternalLink,
  Copy,
  ChevronDown,
  ChevronUp,
} from "lucide-react";

interface RoscaCardProps {
  address: string;
  index: number;
}

export default function RoscaCard({ address, index }: RoscaCardProps) {

  const {address: userAddress, isConnected } = useAccount();
  const { writeContract, isPending } = useWriteContract();
  const [isExpanded, setIsExpanded] = useState(false);
  const [isMember, setIsMember] = useState(false);
  const [copied, setCopied] = useState(false);
  const [isWinner, setIsWinner] = useState(false);
  const [canContribute, setCanContribute] = useState(false);

  // Read committee details
  const { data: contributionAmount } = useReadContract({
    address: address as `0x${string}`,
    abi: CommitteeABI,
    functionName: "i_contributionAmount",
  });

  const { data: currentCycle } = useReadContract({
    address: address as `0x${string}`,
    abi: CommitteeABI,
    functionName: "s_currentCycle",
  });

  const { data: totalCycles } = useReadContract({
    address: address as `0x${string}`,
    abi: CommitteeABI,
    functionName: "i_totalCycles",
  });

  const { data: hasEnded } = useReadContract({
    address: address as `0x${string}`,
    abi: CommitteeABI,
    functionName: "s_hasEnded",
  });

  const { data: totalContribution } = useReadContract({
    address: address as `0x${string}`,
    abi: CommitteeABI,
    functionName: "s_totalContribution",
  });

  const { data: collectionInterval } = useReadContract({
    address: address as `0x${string}`,
    abi: CommitteeABI,
    functionName: "i_collectionInterval",
  });

  //  const { data: memberStatus } = useReadContract({
  //   abi: CommitteeABI,
  //   address: address as `0x${string}`,
  //   functionName: "s_isMember",
  //   args: [userAddress],
  //   // watch: true,
  // });

  useWatchContractEvent({
  address: address as `0x${string}`,
  abi: CommitteeABI,
  eventName: "WinnerPicked",
  onEvent(event) {
    const winner = event.args.winner;

    if (userAddress && winner.toLowerCase() === userAddress.toLowerCase()) {
      setIsWinner(true);
    } else {
      setIsWinner(false);
    }
  },
});
  // useWatchContractEvent({
  //   address: address as `0x${string}`,
  //   abi: CommitteeABI,
  //   eventName: "WinnerPicked",
  //   onLogs(logs) {
  //     logs.forEach((log) => {

  //       const winner = log.args.winner
  //       if (userAddress && winner.toLowerCase() === userAddress.toLowerCase()) {
  //         setIsWinner(true)
  //       } else {
  //       setIsWinner(false);
  //     }
      
  //     })
  //   },
  // });

  const { data: isWinnerOfCycle } = useReadContract({
    abi: CommitteeABI,
    address: address as `0x${string}`,
    functionName: "", // 
    args: [address],
    // watch: true,
  });

  // Calculate progress percentage
  const currentCycleNum = Number(currentCycle || 0);
  const totalCyclesNum = Number(totalCycles || 0);
  const progress =
    totalCyclesNum > 0 ? (currentCycleNum / totalCyclesNum) * 100 : 0;

  // Format contribution amount
  const contributionFormatted = contributionAmount
    ? formatUnits(contributionAmount as bigint, 6)
    : "...";

  const totalContributionFormatted = totalContribution
    ? formatUnits(totalContribution as bigint, 6)
    : "0";

  // Calculate cycle duration in days
  const cycleDurationDays = collectionInterval
    ? Number(collectionInterval) / (24 * 60 * 60)
    : 0;

  // Determine status
  const status = hasEnded ? "completed" : "active";
  const statusColor = hasEnded
    ? "bg-gray-100 text-gray-700 dark:bg-slate-700 dark:text-slate-300"
    : "bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400";

    useEffect(() => {
      // if (memberStatus !== undefined) setIsMember(Boolean(memberStatus));
      if (isWinnerOfCycle !== undefined) setIsWinner(Boolean(isWinnerOfCycle));
      // if (currentCycle < totalCycles) setCanContribute(true); it's not implanted for now
      setCanContribute(true)
    }, [isWinnerOfCycle]);

    const handleCopyAddress = () => {
      navigator.clipboard.writeText(address);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    };

    const handleDeposit = async () => {
      if (!isConnected || !isMember || !canContribute || isPending) return alert("You must be a member!");
      try {
        await writeContract({
          abi: CommitteeABI,
          address: address as `0x${string}`,
          functionName: "depositContribution",
          args: [contributionAmount],
        });
      } catch (err) {
        console.error(err);
        alert("Deposit failed.");
      }
    };

    const handleWithdraw = async () => {
      if (!isConnected || !isWinner) return alert("You’re not the winner.");
      try {
        await writeContract({
          abi: CommitteeABI,
          address: address as `0x${string}`,
          functionName: "withdrawYourShare",
        });
      } catch (err) {
        console.error(err);
        alert("Withdraw failed.");
      }
    };

  return (
    <div className="card group hover:scale-105 transition-transform duration-300">
      {/* Header */}
      <div className="flex justify-between items-start mb-4">
        <div className="flex-1">
          <h3 className="text-xl font-bold text-gray-900 dark:text-slate-100 mb-1">
            ROSCA #{index}
          </h3>
          <div className="flex items-center gap-2">
            <p className="text-xs font-mono text-gray-500 dark:text-slate-400">
              {address.slice(0, 10)}...{address.slice(-8)}
            </p>
            <button
              onClick={handleCopyAddress}
              className="text-gray-400 hover:text-primary-600 dark:hover:text-primary-400 transition-colors"
              title="Copy address"
            >
              {copied ? (
                <span className="text-xs text-green-600 dark:text-green-400">
                  ✓
                </span>
              ) : (
                <Copy className="h-3.5 w-3.5" />
              )}
            </button>
          </div>
        </div>
        <span className={`badge ${statusColor} flex-shrink-0`}>
          {status === "completed" ? "Completed" : "Active"}
        </span>
      </div>

      {/* Main Stats */}
      <div className="grid grid-cols-2 gap-4 mb-4">
        <div className="bg-gradient-to-br from-primary-50 to-primary-100 dark:from-primary-950/30 dark:to-primary-900/30 p-4 rounded-lg border border-primary-200 dark:border-primary-800">
          <div className="flex items-center gap-2 mb-1">
            <DollarSign className="h-4 w-4 text-primary-600 dark:text-primary-400" />
            <p className="text-xs text-gray-600 dark:text-slate-400">
              Contribution
            </p>
          </div>
          <p className="text-lg font-bold text-gray-900 dark:text-slate-100">
            {contributionFormatted} <span className="text-sm">PYUSD</span>
          </p>
        </div>

        <div className="bg-gradient-to-br from-secondary-50 to-secondary-100 dark:from-secondary-950/30 dark:to-secondary-900/30 p-4 rounded-lg border border-secondary-200 dark:border-secondary-800">
          <div className="flex items-center gap-2 mb-1">
            <TrendingUp className="h-4 w-4 text-secondary-600 dark:text-secondary-400" />
            <p className="text-xs text-gray-600 dark:text-slate-400">
              Progress
            </p>
          </div>
          <p className="text-lg font-bold text-gray-900 dark:text-slate-100">
            {currentCycleNum} / {totalCyclesNum}
          </p>
        </div>
      </div>

      {/* Progress Bar */}
      <div className="mb-4">
        <div className="flex justify-between items-center mb-2">
          <span className="text-xs text-gray-600 dark:text-slate-400">
            Cycle Progress
          </span>
          <span className="text-xs font-semibold text-gray-900 dark:text-slate-100">
            {progress.toFixed(0)}%
          </span>
        </div>
        <div className="w-full bg-gray-200 dark:bg-slate-700 rounded-full h-2.5 overflow-hidden">
          <div
            className="bg-gradient-to-r from-primary-500 via-secondary-500 to-accent-500 h-2.5 rounded-full transition-all duration-500"
            style={{ width: `${progress}%` }}
          />
        </div>
      </div>

     {/* Deposit and Withdraw */}
      <div className="flex flex-col gap-3 mt-4">
        {/* Deposit Button */}
        <button
          onClick={handleDeposit}
          // disabled={!canContribute || !isMember || isPending}
          className={`w-full py-2.5 px-4 rounded-lg font-semibold transition-all duration-200
            ${isPending
              ? "bg-gray-300 dark:bg-slate-700 text-gray-500 cursor-not-allowed"
              : "bg-gradient-to-r from-primary-500 via-secondary-500 to-accent-500 text-white hover:opacity-90 shadow-md"
            }`}
        >
          {isPending ? "Processing..." : "Deposit Contribution"}
        </button>

        {isWinner && (
          <button
            onClick={handleWithdraw}
            disabled={isPending}
            className={`w-full py-2.5 px-4 rounded-lg font-semibold transition-all duration-200
              border border-secondary-300 dark:border-secondary-700
              text-secondary-700 dark:text-secondary-300
              hover:bg-secondary-100 dark:hover:bg-secondary-900/30
              shadow-sm`}
          >
            {isPending ? "Processing..." : "Withdraw Your Share"}
          </button>
        )}
      </div>

      {/* Quick Stats */}
      <div className="grid grid-cols-3 gap-2 mb-4">
        <div className="text-center p-2 bg-gray-50 dark:bg-slate-800/50 rounded-lg">
          <Users className="h-4 w-4 text-gray-500 dark:text-slate-400 mx-auto mb-1" />
          <p className="text-xs font-semibold text-gray-900 dark:text-slate-100">
            {totalCyclesNum}
          </p>
          <p className="text-xs text-gray-500 dark:text-slate-400">Members</p>
        </div>
        <div className="text-center p-2 bg-gray-50 dark:bg-slate-800/50 rounded-lg">
          <Calendar className="h-4 w-4 text-gray-500 dark:text-slate-400 mx-auto mb-1" />
          <p className="text-xs font-semibold text-gray-900 dark:text-slate-100">
            {cycleDurationDays}
          </p>
          <p className="text-xs text-gray-500 dark:text-slate-400">Days</p>
        </div>
        <div className="text-center p-2 bg-gray-50 dark:bg-slate-800/50 rounded-lg">
          <DollarSign className="h-4 w-4 text-gray-500 dark:text-slate-400 mx-auto mb-1" />
          <p className="text-xs font-semibold text-gray-900 dark:text-slate-100">
            {(parseFloat(contributionFormatted) * totalCyclesNum).toFixed(2)}
          </p>
          <p className="text-xs text-gray-500 dark:text-slate-400">Total</p>
        </div>
      </div>

      {/* Expandable Section */}
      {isExpanded && (
        <div className="border-t border-gray-200 dark:border-slate-700 pt-4 mt-4 space-y-3">
          <div className="flex justify-between items-center">
            <span className="text-sm text-gray-600 dark:text-slate-400">
              Total Contributions:
            </span>
            <span className="text-sm font-semibold text-gray-900 dark:text-slate-100">
              {totalContributionFormatted} PYUSD
            </span>
          </div>
          <div className="flex justify-between items-center">
            <span className="text-sm text-gray-600 dark:text-slate-400">
              Status:
            </span>
            <span className="text-sm font-semibold text-gray-900 dark:text-slate-100">
              {hasEnded ? "Ended" : "Active"}
            </span>
          </div>
          <div>
            <span className="text-sm text-gray-600 dark:text-slate-400 block mb-1">
              Contract Address:
            </span>
            <div className="flex items-center gap-2 bg-gray-50 dark:bg-slate-800/50 p-2 rounded-lg">
              <p className="font-mono text-xs text-gray-700 dark:text-slate-300 break-all flex-1">
                {address}
              </p>
              <a
                href={`https://etherscan.io/address/${address}`}
                target="_blank"
                rel="noopener noreferrer"
                className="text-primary-600 dark:text-primary-400 hover:text-primary-700 dark:hover:text-primary-300 flex-shrink-0"
                title="View on Etherscan"
              >
                <ExternalLink className="h-4 w-4" />
              </a>
            </div>
          </div>
        </div>
      )}

      {/* Expand/Collapse Button */}
      <button
        onClick={() => setIsExpanded(!isExpanded)}
        className="w-full mt-4 py-2 px-4 text-sm font-medium text-primary-600 dark:text-primary-400 hover:bg-primary-50 dark:hover:bg-primary-900/20 rounded-lg transition-colors flex items-center justify-center gap-2"
      >
        {isExpanded ? (
          <>
            <ChevronUp className="h-4 w-4" />
            Show Less
          </>
        ) : (
          <>
            <ChevronDown className="h-4 w-4" />
            Show More
          </>
        )}
      </button>
    </div>
  );
}
