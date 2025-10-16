"use client";

import Link from "next/link";

import { PlusCircle } from "lucide-react";
import ConnectWallet from "../ConnectWallet";
import { Logo } from "../../common/Logo";

export default function Navbar() {
  return (
    <nav className="bg-white/95 dark:bg-slate-900/95 backdrop-blur-md shadow-lg sticky top-0 z-50 border-b border-gray-100 dark:border-slate-800">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex justify-between h-16">
          <div className="flex items-center">
            <Link href="/" className="flex items-center space-x-3 group">
              <div className="relative">
                <div className="relative transition-all duration-300 group-hover:scale-105">
                  <Logo />
                </div>
              </div>
            </Link>
          </div>

          <div className="hidden md:flex items-center space-x-4">
            <Link
              href="/pages/analytics"
              className="text-gray-700 dark:text-slate-300 hover:text-primary-600 dark:hover:text-primary-400 px-3 py-2 rounded-md text-sm font-medium transition-colors"
            >
              Analytics
            </Link>
            <Link
              href="/pages/my-roscas"
              className="text-gray-700 dark:text-slate-300 hover:text-primary-600 dark:hover:text-primary-400 px-3 py-2 rounded-md text-sm font-medium transition-colors"
            >
              My ROSCAs
            </Link>

            <Link
              href="/pages/create-rosca"
              className="flex items-center space-x-1 text-gray-700 dark:text-slate-300 hover:text-primary-600 dark:hover:text-primary-400 px-3 py-2 rounded-md text-sm font-medium transition-colors"
            >
              <PlusCircle className="h-4 w-4" />
              <span>Create ROSCA</span>
            </Link>

            <ConnectWallet />
          </div>
        </div>
      </div>
    </nav>
  );
}
