'use client';

import { useSignAndExecuteTransaction } from '@mysten/dapp-kit';
import { Transaction } from '@mysten/sui/transactions';
import { PACKAGE_ID, FARM_REGISTRY_ID, CLOCK_ID } from '@/lib/constants';

/**
 * Provides PTB (Programmable Transaction Block) wrappers for all game actions.
 * Each function builds a transaction and submits it via the connected wallet.
 */
export function useGameActions() {
  const { mutate: signAndExecute, isPending } = useSignAndExecuteTransaction();

  function createFarm(onSuccess: () => void) {
    const tx = new Transaction();
    tx.moveCall({
      target: `${PACKAGE_ID}::farm::create_farm`,
      arguments: [tx.object(FARM_REGISTRY_ID)],
    });
    signAndExecute({ transaction: tx }, { onSuccess });
  }

  function plantCrop(
    farmId: string,
    plotIndex: number,
    cropType: number,
    onSuccess: () => void
  ) {
    const tx = new Transaction();
    tx.moveCall({
      target: `${PACKAGE_ID}::farm::plant`,
      arguments: [
        tx.object(farmId),
        tx.object(FARM_REGISTRY_ID),
        tx.object(CLOCK_ID), // always 0x6
        tx.pure.u8(plotIndex),
        tx.pure.u8(cropType),
      ],
    });
    signAndExecute({ transaction: tx }, { onSuccess });
  }

  function harvestCrop(
    farmId: string,
    plotIndex: number,
    onSuccess: () => void
  ) {
    const tx = new Transaction();
    tx.moveCall({
      target: `${PACKAGE_ID}::farm::harvest`,
      arguments: [
        tx.object(farmId),
        tx.object(FARM_REGISTRY_ID),
        tx.object(CLOCK_ID),
        tx.pure.u8(plotIndex),
      ],
    });
    signAndExecute({ transaction: tx }, { onSuccess });
  }

  return { createFarm, plantCrop, harvestCrop, isPending };
}
