// SafeSetupPage.tsx
"use client";
import { useState } from "react";
import { useAccount } from "wagmi";
import useSafeProtocolKit from "../../hooks/useSafeProtocolKit";
import {
  PlusCircle,
  Trash2,
} from "lucide-react";

export default function SafeSetupPage({ onSafeConnected }) {
  const { address } = useAccount();
  const {
    initSafeProtocolKit,
    createSafeWallet,
    connectSafeWallet,
    getSafeAddress,
    isSafeDeployed,
  } = useSafeProtocolKit();

  const [owners, setOwners] = useState<string[]>([]);
  const [threshold, setThreshold] = useState(1);
  const [existingSafe, setExistingSafe] = useState("");
  const [loading, setLoading] = useState(false);

  async function handleCreateSafe() {
  
    setLoading(true);
    await initSafeProtocolKit([address!, ...owners], threshold);
    const newSafeAddress = await createSafeWallet();
    if (newSafeAddress) onSafeConnected(newSafeAddress);
    setLoading(false);
  }

  async function handleConnectSafe() {
    setLoading(true);
    await initSafeProtocolKit([address!], 1);
    await connectSafeWallet(existingSafe as `0x${string}`);
    const deployed = await isSafeDeployed();
    if (deployed) onSafeConnected(existingSafe);
    setLoading(false);
  }

  const addOwner = () => {
      setOwners([...owners, ""]);
    };

    const updateOwner = (index: number, value: string) => {
      const updated = [...owners];
      updated[index] = value;
      setOwners(updated);
    };

    const deleteOwner = (index: number) => {
      const updated = [...owners];
      updated.splice(index, 1);
      setOwners(updated);
    };


    // const handleCreateSafe = async () => {
    //   if (threshold > owners.length) {
    //     alert("Threshold cannot be greater than number of owners");
    //     return;
    //   }

    //   console.log("Owners:", owners);
    //   console.log("Threshold:", threshold);

    //   // Example:
    //   await contract.createSafe(owners, threshold);
    // };

  return (
    <div className="flex flex-col gap-4">
      {/* Connect existing Safe */}
      <div>
        <input
          type="text"
          value={existingSafe}
          onChange={(e) => setExistingSafe(e.target.value)}
          placeholder="Enter Safe address"
          className="w-full p-2 border rounded-md bg-white dark:bg-slate-700"
        />
        <button
          onClick={handleConnectSafe}
          className="bg-blue-500 text-white px-3 py-2 rounded-md mt-2 w-full"
          disabled={loading}
        >
          {loading ? "Connecting..." : "Connect Existing Safe"}
        </button>
      </div>

      {/* Create new Safe */}
      <div className="space-y-3">
        {owners.map((owner, index) => (
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
                  Owner Address *
                </label>
                <input
                  type="text"
                  id={`wallet-${index}`}
                  value={owner}
                  onChange={(e) => updateOwner(index, e.target.value)}
                  required
                  className="w-full px-3 py-2 border border-gray-300 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-700 text-gray-900 dark:text-slate-100 placeholder-gray-400 dark:placeholder-slate-500 focus:ring-2 focus:ring-primary-500 focus:border-transparent text-sm font-mono"
                  placeholder="0x..."
                />
              </div>
              {owners.length > 1 && (
                <button
                  type="button"
                  onClick={() => deleteOwner(index)}
                  className="flex-shrink-0 h-8 w-8 flex items-center justify-center text-red-600 dark:text-red-400 hover:bg-red-50 dark:hover:bg-red-900/20 rounded-lg transition-colors"
                  title="Remove owner"
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
          onClick={addOwner}
          className="w-full py-3 px-4 border-2 border-dashed border-gray-300 dark:border-slate-600 rounded-lg text-primary-600 dark:text-primary-400 hover:border-primary-400 dark:hover:border-primary-500 hover:bg-primary-50 dark:hover:bg-primary-900/10 font-medium transition-colors flex items-center justify-center"
        >
          <PlusCircle className="h-5 w-5 mr-2" />
          Add Another Owner
        </button>

        <div className="mt-4">
          <label className="block text-xs font-medium text-gray-700 dark:text-slate-300 mb-1.5">
            Threshold (signatures required)
          </label>
          <input
            type="number"
            value={threshold}
            onChange={(e) => setThreshold(Number(e.target.value))}
            min="1"
            max={owners.length}
            className="w-full px-3 py-2 border border-gray-300 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-700 text-gray-900 dark:text-slate-100 placeholder-gray-400 dark:placeholder-slate-500 focus:ring-2 focus:ring-primary-500 focus:border-transparent text-sm"
          />
        </div>

        <button
          onClick={handleCreateSafe}
          className="mt-6 w-full bg-primary-600 hover:bg-primary-700 text-white py-3 rounded-lg font-medium transition-colors"
        >
          Create Safe
        </button>
      </div>
      {/* <div>
        <input
          type="text"
          placeholder="Add owner address"
          className="w-full p-2 border rounded-md bg-white dark:bg-slate-700"
          onKeyDown={(e) => {
            if (e.key === "Enter" && e.currentTarget.value) {
              setOwners([...owners, e.currentTarget.value]);
              e.currentTarget.value = "";
            }
          }}
        />
        <input
          type="number"
          placeholder="Threshold"
          value={threshold}
          onChange={(e) => setThreshold(Number(e.target.value))}
          className="w-full p-2 border rounded-md mt-2 bg-white dark:bg-slate-700"
        />
        <button
          onClick={handleCreateSafe}
          className="bg-green-600 text-white px-3 py-2 rounded-md mt-2 w-full"
          disabled={loading}
        >
          {loading ? "Creating..." : "Create New Safe"}
        </button>
      </div> */}
    </div>
  );
}