'use client';

import { useState } from 'react';
import Link from 'next/link';
import { useCurrentAccount } from '@mysten/dapp-kit';
import { useFarm } from '@/hooks/useFarm';
import { useGameActions } from '@/hooks/useGameActions';
import { FarmGrid } from '@/components/farm/FarmGrid';
import { CROP_TYPES, CropTypeId } from '@/lib/constants';
import { getReadyAtMs } from '@/lib/utils';

export default function FarmPage() {
  const account = useCurrentAccount();
  const { farm, isPending, refetch, hasFarm } = useFarm();
  const { createFarm, plantCrop, harvestCrop, isPending: txPending } = useGameActions();

  // Index of the plot awaiting crop selection, or null when no selection active
  const [selectedPlotIndex, setSelectedPlotIndex] = useState<number | null>(null);
  const [txError, setTxError] = useState<string | null>(null);

  if (!account) {
    return (
      <main className="flex min-h-screen items-center justify-center">
        <p className="text-amber-700 text-lg">Connect your wallet to play</p>
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
    if (!farm || txPending) return;
    const plot = farm.plots[plotIndex];

    if (plot.state === 0) {
      // Empty — open crop selector
      setSelectedPlotIndex(plotIndex);
      setTxError(null);
    } else if (plot.state === 1) {
      // Only harvest if fully grown — prevents wasting gas on a doomed tx
      const nowMs = BigInt(Date.now());
      if (nowMs >= getReadyAtMs(plot)) {
        harvestCrop(
          farm.id,
          plotIndex,
          () => refetch(),
          (e) => setTxError(e.message)
        );
      }
      // Growing but not ready — do nothing (PlotTile shows cursor-default)
    }
  }

  function handleCropSelect(cropType: CropTypeId) {
    if (selectedPlotIndex === null || !farm) return;
    const idx = selectedPlotIndex;
    setSelectedPlotIndex(null);
    plantCrop(
      farm.id,
      idx,
      cropType,
      () => refetch(),
      (e) => setTxError(e.message)
    );
  }

  return (
    <main className="flex min-h-screen flex-col items-center justify-center gap-8 p-8">
      {/* Back navigation */}
      <div className="absolute top-4 left-4">
        <Link href="/" className="text-sm text-amber-700 hover:text-amber-900 transition-colors">
          ← Home
        </Link>
      </div>

      <h1 className="text-3xl font-bold text-amber-800">🌿 My Grove</h1>

      {!hasFarm ? (
        <div className="flex flex-col items-center gap-4">
          <p className="text-amber-700">You don&apos;t have a farm yet.</p>
          <button
            onClick={() =>
              createFarm(
                () => refetch(),
                (e) => setTxError(e.message)
              )
            }
            disabled={txPending}
            className="px-6 py-3 bg-green-600 hover:bg-green-700 disabled:opacity-50 text-white font-semibold rounded-lg transition-colors"
          >
            {txPending ? 'Creating...' : 'Create Farm'}
          </button>
        </div>
      ) : (
        <div className="flex flex-col items-center gap-6">
          <FarmGrid farm={farm!} onPlotClick={handlePlotClick} disabled={txPending} />
          <p className="text-xs text-gray-400">
            Click an empty plot to plant · Click a glowing plot to harvest
          </p>

          {/* Transaction error */}
          {txError && (
            <div className="flex items-center gap-2 px-4 py-2 bg-red-100 border border-red-300 rounded-lg text-sm text-red-700">
              <span>{txError}</span>
              <button
                onClick={() => setTxError(null)}
                className="ml-2 text-red-500 hover:text-red-700 font-bold"
              >
                ✕
              </button>
            </div>
          )}
        </div>
      )}

      {/* Crop selector overlay */}
      {selectedPlotIndex !== null && (
        <div className="fixed inset-0 bg-black/40 flex items-center justify-center z-10">
          <div className="bg-white rounded-2xl shadow-xl p-6 flex flex-col gap-4 min-w-[320px]">
            <h2 className="text-lg font-semibold text-amber-800">
              Choose a crop for plot #{selectedPlotIndex + 1}
            </h2>

            <div className="flex gap-3">
              {(Object.entries(CROP_TYPES) as [string, typeof CROP_TYPES[CropTypeId]][]).map(
                ([id, crop]) => (
                  <button
                    key={id}
                    onClick={() => handleCropSelect(Number(id) as CropTypeId)}
                    className="flex-1 flex flex-col items-center gap-1 p-3 rounded-xl border-2 border-amber-200 hover:border-amber-500 hover:bg-amber-50 transition-all"
                  >
                    <span className="text-3xl">{crop.emoji}</span>
                    <span className="text-sm font-semibold text-gray-700">{crop.name}</span>
                    <span className="text-xs text-gray-500">{crop.growMinutes}m</span>
                    <span className="text-xs text-green-700 font-medium">{crop.reward} GROVE</span>
                  </button>
                )
              )}
            </div>

            <button
              onClick={() => setSelectedPlotIndex(null)}
              className="mt-1 text-sm text-gray-400 hover:text-gray-600 self-end"
            >
              Cancel
            </button>
          </div>
        </div>
      )}
    </main>
  );
}
