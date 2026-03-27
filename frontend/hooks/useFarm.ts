'use client';

import { useSuiClientQuery, useCurrentAccount } from '@mysten/dapp-kit';
import { PACKAGE_ID } from '@/lib/constants';
import type { Farm, Plot } from '@/types/farm';

/**
 * Fetches the current player's Farm object from Sui.
 * Returns null if the wallet is not connected or no Farm exists yet.
 */
export function useFarm() {
  const account = useCurrentAccount();

  const { data, isPending, refetch } = useSuiClientQuery(
    'getOwnedObjects',
    {
      owner: account?.address ?? '',
      filter: { StructType: `${PACKAGE_ID}::farm::Farm` },
      options: { showContent: true },
    },
    { enabled: !!account && !!PACKAGE_ID }
  );

  const farmObject = data?.data?.[0];
  const farm: Farm | null =
    farmObject?.data?.content?.dataType === 'moveObject'
      ? parseFarmObject(
          (farmObject.data.content as { fields: Record<string, unknown> }).fields
        )
      : null;

  return { farm, isPending, refetch, hasFarm: !!farm };
}

function parseFarmObject(fields: Record<string, unknown>): Farm {
  const rawPlots = fields.plots as unknown[];
  return {
    id: (fields.id as { id: string }).id,
    owner: fields.owner as string,
    plotCount: Number(fields.plot_count),
    plots: rawPlots.map((p) => {
      const plot = (p as { fields: Record<string, unknown> }).fields;
      return {
        index: Number(plot.index),
        state: Number(plot.state) as 0 | 1,
        cropType: Number(plot.crop_type),
        plantedAtMs: BigInt(plot.planted_at_ms as string),
        growDurationMs: BigInt(plot.grow_duration_ms as string),
      } satisfies Plot;
    }),
  };
}
