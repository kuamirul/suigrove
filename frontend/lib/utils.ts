import type { Plot } from '@/types/farm';

/**
 * Returns growth percentage (0–100) for a planted crop.
 * Runs client-side with Date.now() for display only.
 * The contract is the authoritative source at harvest time.
 */
export function getGrowthPercent(plot: Plot, nowMs: bigint): number {
  if (plot.state !== 1) return 0;
  const elapsed = nowMs - plot.plantedAtMs;
  if (elapsed <= 0n) return 0;
  const pct = Number((elapsed * 100n) / plot.growDurationMs);
  return Math.min(pct, 100);
}

export function getReadyAtMs(plot: Plot): bigint {
  return plot.plantedAtMs + plot.growDurationMs;
}

/** Formats a millisecond duration as "Xm Ys" */
export function msToMinutesSeconds(ms: bigint): string {
  if (ms <= 0n) return '0m 0s';
  const totalSeconds = Number(ms / 1000n);
  const m = Math.floor(totalSeconds / 60);
  const s = totalSeconds % 60;
  return `${m}m ${s}s`;
}

/** Shortens a Sui address for display: 0x1234...abcd */
export function shortenAddress(address: string): string {
  if (address.length <= 10) return address;
  return `${address.slice(0, 6)}...${address.slice(-4)}`;
}
