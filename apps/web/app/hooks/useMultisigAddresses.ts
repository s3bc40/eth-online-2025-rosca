import { useCallback } from "react";

export function useMultisigAddresses() {
  const getAddressesLocalStorage = useCallback((): string[] => {
    const stored = localStorage.getItem("ROSCA__multisigAddresses");
    return stored ? JSON.parse(stored) : [];
  }, []);

  const addAddressLocalStorage = useCallback(
    (address: string) => {
      const addresses = getAddressesLocalStorage();
      if (!addresses.includes(address)) {
        addresses.push(address);
        localStorage.setItem(
          "ROSCA__multisigAddresses",
          JSON.stringify(addresses)
        );
      }
    },
    [getAddressesLocalStorage]
  );

  return { getAddressesLocalStorage, addAddressLocalStorage };
}
