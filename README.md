# 🌿 SuiGrove

A web-based farming game on the [Sui blockchain](https://sui.io). Plant crops, wait for them to grow, and harvest GROVE tokens as rewards. Built as a learning project for blockchain game development.

**Live demo:** _coming soon (Vercel)_

---

## How it works

- Connect your Sui wallet (Slush, Sui Wallet, etc.)
- Create your farm — a Sui owned object with 4 starter plots
- Plant one of 3 crop types on any empty plot
- Wait for the crop to grow (5 – 60 minutes depending on type)
- Harvest to mint GROVE tokens directly to your wallet

All game state lives on-chain. No backend, no database.

| Crop | Grow time | Reward |
|---|---|---|
| 🌾 Wheat | 5 min | 10 GROVE |
| 🌽 Corn | 15 min | 35 GROVE |
| 🎃 Pumpkin | 60 min | 200 GROVE |

---

## Tech stack

| Layer | Technology |
|---|---|
| Smart contracts | Sui Move (2024 edition) |
| Frontend | Next.js 14 (App Router) + TypeScript |
| Styling | Tailwind CSS |
| Blockchain SDK | `@mysten/dapp-kit` + `@mysten/sui` |
| Deploy | Vercel (frontend) · Sui Testnet (contracts) |

---

## Project structure

```
suigrove/
├── contracts/
│   ├── Move.toml
│   ├── sources/
│   │   ├── farm_token.move      # GROVE coin (One Time Witness pattern)
│   │   ├── farm_registry.move   # Shared singleton: crop configs + mint authority
│   │   └── farm.move            # Farm object: create, plant, harvest
│   └── tests/
│       └── farm_tests.move
├── frontend/
│   ├── app/
│   │   ├── page.tsx             # Landing page
│   │   └── farm/page.tsx        # Main game page
│   ├── components/farm/         # FarmGrid, PlotTile
│   ├── hooks/                   # useFarm, useGameActions
│   ├── lib/                     # constants, utils
│   ├── providers/               # Sui provider stack
│   └── types/                   # TypeScript mirrors of Move structs
└── scripts/
    └── deploy.sh                # Testnet deploy helper (run in WSL)
```

---

## Running locally

**Prerequisites:** Node 18+, a Sui wallet browser extension

```bash
# Clone the repo
git clone https://github.com/kuamirul/suigrove.git
cd suigrove

# Install frontend dependencies
cd frontend
npm install

# Copy env file and fill in contract addresses
cp .env.local.example .env.local
```

Create `frontend/.env.local`:
```env
NEXT_PUBLIC_PACKAGE_ID=0xec969313b1fb0bfea8bd75b99f502f632a720a418f05c27e6c91c79a1a6cc565
NEXT_PUBLIC_FARM_REGISTRY_ID=0x8c2109de23ff6980365c8fdfaec2fef1dc44718e7c6426d5862023745d09bb3d
NEXT_PUBLIC_NETWORK=testnet
```

```bash
npm run dev
# → http://localhost:3000
```

---

## Deploying contracts (WSL / Linux)

**Prerequisites:** [Sui CLI](https://docs.sui.io/guides/developer/getting-started/sui-install), testnet wallet with SUI

```bash
# Configure testnet (first time only)
sui client new-env --alias testnet --rpc https://fullnode.testnet.sui.io:443
sui client switch --env testnet
sui client faucet

# Build and publish
cd contracts
sui move build
sui client publish --gas-budget 100000000

# After publish — note PackageID, AdminCap, TreasuryCap from output, then:
sui client call \
  --package $PACKAGE_ID \
  --module farm_registry \
  --function initialize_registry \
  --args $ADMIN_CAP_ID $TREASURY_CAP_ID \
  --gas-budget 10000000

# Update frontend/.env.local with the new addresses
```

---

## Roadmap

- [x] **Phase 1** — On-chain MVP: create farm, plant, harvest, GROVE tokens
- [ ] **Phase 2** — All crop types, farm expansion, countdown timers, better UX
- [ ] **Phase 3** — Phaser 3 visuals, watering mechanic, leaderboard
- [ ] **Phase 4** — Mainnet, land NFTs, seasonal events
