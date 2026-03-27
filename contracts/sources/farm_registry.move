module suigrove::farm_registry;
// TODO Phase 1: Shared FarmRegistry object holding TreasuryCap and crop configs
//
// This module will define:
//   - FarmRegistry shared object (treasury_cap, total_farms, crop_configs table)
//   - CropConfig struct (grow_duration_ms, harvest_reward)
//   - AdminCap owned object
//   - initialize_registry() entry — called once post-deploy to wrap TreasuryCap
//   - add_crop_type() entry — admin only
//   - get_crop_config() public accessor
//   - mint_farm_reward() package-internal mint helper
//   - increment_total_farms() called by farm module
