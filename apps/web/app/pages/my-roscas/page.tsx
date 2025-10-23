"use client";

import { useState, useMemo } from "react";
import Navbar from "../../components/Navbar";
import { useAccount, useChainId, useReadContract } from "wagmi";
import FactoryABI from "@repo/foundry-utils/abis/Factory.json";
import { getFactoryContractAddress } from "../../utils/helpers";
import { ArrowLeft, Users, Search, Filter } from "lucide-react";
import Link from "next/link";
import RoscaCard from "../../components/RoscaCard";

export default function MyRoscas() {
  const [searchTerm, setSearchTerm] = useState("");
  const [filterStatus, setFilterStatus] = useState<
    "all" | "active" | "completed"
  >("all");

  const { address } = useAccount();
  const chainId = useChainId();
  const factoryAddress = getFactoryContractAddress(chainId);

  // Get all committees for the connected wallet address
  const {
    data: committees,
    isLoading,
    error,
  } = useReadContract({
    address: factoryAddress,
    abi: FactoryABI,
    functionName: "getCommittees",
    args: address ? [address] : undefined,
  });

  const committeeAddresses = (committees as string[]) || [];

  // Filter committees based on search term
  const filteredCommittees = useMemo(() => {
    if (!committeeAddresses) return [];
    return committeeAddresses.filter((addr) =>
      addr.toLowerCase().includes(searchTerm.toLowerCase())
    );
  }, [committeeAddresses, searchTerm]);

  // Calculate status counts (would need to fetch status for each committee)
  const statusCounts = {
    all: committeeAddresses?.length || 0,
    active: committeeAddresses?.length || 0, // TODO: Calculate based on actual status
    completed: 0, // TODO: Calculate based on actual status
  };

  return (
    <div>
      <Navbar />
      <div className="min-h-screen py-12">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          {/* Header */}
          <div className="mb-8">
            <h1 className="text-3xl font-bold text-gray-900 dark:text-slate-100 mb-2">
              My ROSCAs
            </h1>
            <p className="text-gray-600 dark:text-slate-400">
              Manage all your savings circles in one place
            </p>
          </div>

          {/* Wallet Not Connected */}
          {!address && (
            <div className="card text-center py-12">
              <Users className="h-16 w-16 text-gray-300 dark:text-slate-600 mx-auto mb-4" />
              <h3 className="text-xl font-semibold text-gray-900 dark:text-slate-100 mb-2">
                Wallet Not Connected
              </h3>
              <p className="text-gray-600 dark:text-slate-400 mb-6">
                Please connect your wallet to view your ROSCAs
              </p>
            </div>
          )}

          {/* Loading State */}
          {address && isLoading && (
            <div className="card text-center py-12">
              <div className="animate-spin rounded-full h-16 w-16 border-b-2 border-primary-600 dark:border-primary-400 mx-auto mb-4"></div>
              <p className="text-gray-600 dark:text-slate-400">
                Loading your ROSCAs...
              </p>
            </div>
          )}

          {/* Error State */}
          {address && error && (
            <div className="card border-red-200 dark:border-red-800 bg-red-50 dark:bg-red-900/20 py-8 text-center">
              <p className="text-red-700 dark:text-red-400">
                Error loading ROSCAs: {error.message}
              </p>
            </div>
          )}

          {/* Content - Only show when wallet is connected and loaded */}
          {address && !isLoading && !error && (
            <>
              {/* Stats Bar */}
              <div className="grid grid-cols-2 md:grid-cols-3 gap-4 mb-8">
                <button
                  onClick={() => setFilterStatus("all")}
                  className={`card text-center cursor-pointer transition-all ${
                    filterStatus === "all"
                      ? "ring-2 ring-primary-500 dark:ring-primary-400 bg-gradient-to-br from-primary-50 to-primary-100 dark:from-primary-950/40 dark:to-primary-900/40 shadow-lg"
                      : "hover:shadow-lg hover:scale-105"
                  }`}
                >
                  <p className="text-2xl font-bold text-gray-900 dark:text-slate-100">
                    {statusCounts.all}
                  </p>
                  <p className="text-sm text-gray-600 dark:text-slate-400 font-medium">
                    Total
                  </p>
                </button>
                <button
                  onClick={() => setFilterStatus("active")}
                  className={`card text-center cursor-pointer transition-all ${
                    filterStatus === "active"
                      ? "ring-2 ring-secondary-500 dark:ring-secondary-400 bg-gradient-to-br from-secondary-50 to-secondary-100 dark:from-secondary-950/40 dark:to-secondary-900/40 shadow-lg"
                      : "hover:shadow-lg hover:scale-105"
                  }`}
                >
                  <p className="text-2xl font-bold text-secondary-700 dark:text-secondary-400">
                    {statusCounts.active}
                  </p>
                  <p className="text-sm text-gray-600 dark:text-slate-400 font-medium">
                    Active
                  </p>
                </button>
                <button
                  onClick={() => setFilterStatus("completed")}
                  className={`card text-center cursor-pointer transition-all ${
                    filterStatus === "completed"
                      ? "ring-2 ring-gray-500 dark:ring-slate-500 bg-gradient-to-br from-gray-50 to-gray-100 dark:from-slate-800/40 dark:to-slate-700/40 shadow-lg"
                      : "hover:shadow-lg hover:scale-105"
                  }`}
                >
                  <p className="text-2xl font-bold text-gray-700 dark:text-slate-300">
                    {statusCounts.completed}
                  </p>
                  <p className="text-sm text-gray-600 dark:text-slate-400 font-medium">
                    Completed
                  </p>
                </button>
              </div>

              {/* Search and Filter */}
              <div className="card mb-8">
                <div className="flex flex-col md:flex-row gap-4">
                  <div className="flex-1 relative">
                    <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-5 w-5 text-gray-400 dark:text-slate-500" />
                    <input
                      type="text"
                      placeholder="Search by address..."
                      value={searchTerm}
                      onChange={(e) => setSearchTerm(e.target.value)}
                      className="w-full pl-10 pr-4 py-2 border border-gray-300 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-700 text-gray-900 dark:text-slate-100 placeholder-gray-400 dark:placeholder-slate-500 focus:ring-2 focus:ring-primary-500 focus:border-transparent"
                    />
                  </div>
                  <div className="flex items-center gap-2">
                    <Filter className="h-5 w-5 text-gray-500 dark:text-slate-400" />
                    <select
                      value={filterStatus}
                      onChange={(e) => setFilterStatus(e.target.value as any)}
                      className="px-4 py-2 border border-gray-300 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-700 text-gray-900 dark:text-slate-100 focus:ring-2 focus:ring-primary-500 focus:border-transparent"
                    >
                      <option value="all">All Status</option>
                      <option value="active">Active</option>
                      <option value="completed">Completed</option>
                    </select>
                  </div>
                </div>
              </div>

              {/* ROSCA Grid */}
              {filteredCommittees.length > 0 ? (
                <div className="grid grid-cols-1 lg:grid-cols-2 xl:grid-cols-3 gap-6">
                  {filteredCommittees.map((committeeAddress, index) => (
                    <RoscaCard
                      key={committeeAddress}
                      address={committeeAddress}
                      index={index + 1}
                    />
                  ))}
                </div>
              ) : (
                <div className="card text-center py-12">
                  <Users className="h-16 w-16 text-gray-300 dark:text-slate-600 mx-auto mb-4" />
                  <h3 className="text-xl font-semibold text-gray-900 dark:text-slate-100 mb-2">
                    No ROSCAs Found
                  </h3>
                  <p className="text-gray-600 dark:text-slate-400 mb-6">
                    {searchTerm || filterStatus !== "all"
                      ? "Try adjusting your search or filter"
                      : "Get started by creating your first ROSCA"}
                  </p>
                  {!searchTerm && filterStatus === "all" && (
                    <Link
                      href="/pages/create-rosca"
                      className="btn-primary inline-block"
                    >
                      Create Your First ROSCA
                    </Link>
                  )}
                </div>
              )}
            </>
          )}
        </div>
      </div>
    </div>
  );
}
