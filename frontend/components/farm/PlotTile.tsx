'use client';

import { Plot } from '@/types/farm';
import { CROP_TYPES, CropTypeId } from '@/lib/constants';
import { getGrowthPercent, msToMinutesSeconds, getReadyAtMs } from '@/lib/utils';

interface Props {
  plot: Plot;
  onClick: () => void;
  disabled?: boolean;
}

export function PlotTile({ plot, onClick, disabled = false }: Props) {
  const nowMs = BigInt(Date.now());
  const growthPercent = plot.state === 1 ? getGrowthPercent(plot, nowMs) : 0;
  const isReady = plot.state === 1 && growthPercent >= 100;
  const crop = CROP_TYPES[plot.cropType as CropTypeId];
  const timeRemaining =
    plot.state === 1 && !isReady
      ? msToMinutesSeconds(getReadyAtMs(plot) - nowMs)
      : null;

  const tileClass = [
    'w-16 h-16 rounded border-2 border-amber-700 flex flex-col items-center justify-center text-2xl transition-all select-none',
    plot.state === 0
      ? 'bg-amber-200 hover:bg-amber-300 cursor-pointer'
      : isReady
      ? 'bg-green-400 hover:bg-green-500 cursor-pointer animate-pulse'
      : 'bg-green-200 cursor-default',
    disabled ? 'opacity-50 pointer-events-none' : '',
  ]
    .filter(Boolean)
    .join(' ');

  const title =
    plot.state === 0
      ? 'Empty plot — click to plant'
      : isReady
      ? `${crop?.name} ready — click to harvest!`
      : `${crop?.name} growing — ${timeRemaining} remaining`;

  return (
    <button
      onClick={onClick}
      className={tileClass}
      title={title}
      disabled={disabled}
    >
      {plot.state === 0 && (
        <span className="text-amber-600 text-lg font-bold">+</span>
      )}
      {plot.state === 1 && (
        <>
          <span>{crop?.emoji ?? '🌱'}</span>
          {/* Growth bar */}
          <div className="w-12 h-1 bg-gray-300 rounded mt-1">
            <div
              className="h-1 bg-green-600 rounded transition-all"
              style={{ width: `${growthPercent}%` }}
            />
          </div>
        </>
      )}
    </button>
  );
}
