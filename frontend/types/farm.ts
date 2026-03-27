/** Mirrors the Move Plot struct embedded in Farm.plots */
export interface Plot {
  index: number;
  /** 0 = empty, 1 = planted */
  state: 0 | 1;
  cropType: number;
  /** Clock timestamp (ms) when planted — BigInt because Move u64 exceeds JS number */
  plantedAtMs: bigint;
  /** Grow duration in ms, copied from CropConfig at plant time */
  growDurationMs: bigint;
}

/** Mirrors the Move Farm object */
export interface Farm {
  /** Sui object ID */
  id: string;
  owner: string;
  plotCount: number;
  plots: Plot[];
}
