export const PACKAGE_ID = process.env.NEXT_PUBLIC_PACKAGE_ID ?? '';
export const FARM_REGISTRY_ID = process.env.NEXT_PUBLIC_FARM_REGISTRY_ID ?? '';
export const CLOCK_ID = '0x6'; // Sui system clock — always this address on all networks

export const CROP_TYPES = {
  0: { name: 'Wheat',   emoji: '🌾', growMinutes: 5,  reward: 10  },
  1: { name: 'Corn',    emoji: '🌽', growMinutes: 15, reward: 35  },
  2: { name: 'Pumpkin', emoji: '🎃', growMinutes: 60, reward: 200 },
} as const;

export type CropTypeId = keyof typeof CROP_TYPES;
