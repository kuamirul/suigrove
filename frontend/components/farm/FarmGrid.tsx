'use client';

import { Farm } from '@/types/farm';
import { PlotTile } from './PlotTile';

interface Props {
  farm: Farm;
  onPlotClick: (plotIndex: number) => void;
  disabled?: boolean;
}

export function FarmGrid({ farm, onPlotClick, disabled = false }: Props) {
  return (
    <div className="flex flex-col items-center gap-2">
      <p className="text-sm text-gray-500">
        {farm.plotCount} plot{farm.plotCount !== 1 ? 's' : ''}
      </p>
      {/* Responsive grid: up to 5 columns */}
      <div
        className="grid gap-2"
        style={{
          gridTemplateColumns: `repeat(${Math.min(farm.plotCount, 5)}, 4rem)`,
        }}
      >
        {farm.plots.map((plot) => (
          <PlotTile
            key={plot.index}
            plot={plot}
            onClick={() => onPlotClick(plot.index)}
            disabled={disabled}
          />
        ))}
      </div>
    </div>
  );
}
