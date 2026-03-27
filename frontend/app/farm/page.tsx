'use client';

import { useCurrentAccount } from '@mysten/dapp-kit';
import { useFarm } from '@/hooks/useFarm';
import { useGameActions } from '@/hooks/useGameActions';
import { FarmGrid } from '@/components/farm/FarmGrid';

export default function FarmPage() {
  const account = useCurrentAccount();
  const { farm, isPending, refetch, hasFarm } = useFarm();
  const { createFarm, plantCrop, harvestCrop, isPending: txPending } = useGameActions();

  if (!account) {
    return (
      <main className="flex min-h-screen items-center justify-center">
        <p className="text-amber-700 text-lg">
          Connect your wallet to play
        </p>
      </main>
    );
  }

  if (isPending) {
    return (
      <main className="flex min-h-screen items-center justify-center">
        <p className="text-gray-500">Loading farm...</p>
      </main>
    );
  }

  function handlePlotClick(plotIndex: number) {
    if (!farm) return;
    const plot = farm.plots[plotIndex];
    if (plot.state === 0) {
      // TODO Phase 1: show crop selection UI, then plant
      plantCrop(farm.id, plotIndex, 0, () => refetch());
    } else if (plot.state === 1) {
      harvestCrop(farm.id, plotIndex, () => refetch());
    }
  }

  return (
    <main className="flex min-h-screen flex-col items-center justify-center gap-8 p-8">
      <h1 className="text-3xl font-bold text-amber-800">🌿 My Grove</h1>

      {!hasFarm ? (
        <div className="flex flex-col items-center gap-4">
          <p className="text-amber-700">You don&apos;t have a farm yet.</p>
          <button
            onClick={() => createFarm(() => refetch())}
            disabled={txPending}
            className="px-6 py-3 bg-green-600 hover:bg-green-700 disabled:opacity-50 text-white font-semibold rounded-lg transition-colors"
          >
            {txPending ? 'Creating...' : 'Create Farm'}
          </button>
        </div>
      ) : (
        <div className="flex flex-col items-center gap-6">
          <FarmGrid
            farm={farm!}
            onPlotClick={handlePlotClick}
            disabled={txPending}
          />
          <p className="text-xs text-gray-400">
            Click an empty plot to plant · Click a glowing plot to harvest
          </p>
        </div>
      )}
    </main>
  );
}
