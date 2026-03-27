module suigrove::farm;
// TODO Phase 1: Farm, Plot structs + create_farm, plant, harvest entry functions
//
// This module will define:
//   - Farm object (key, store) — owned by player
//   - Plot struct (store, copy, drop) — embedded in Farm.plots vector
//   - Plot states: 0=empty, 1=planted
//   - Events: FarmCreated, CropPlanted, CropHarvested
//   - create_farm() — mints Farm with 4 starter plots to caller
//   - plant(farm, registry, clock, plot_index, crop_type)
//   - harvest(farm, registry, clock, plot_index)
//   - expand_farm(farm, payment, registry) — burns 50 FARM, adds 1 plot (max 25)
//
// Key: uses sui::clock::timestamp_ms(&clock) for all time checks.
// Clock object address is always 0x6.
