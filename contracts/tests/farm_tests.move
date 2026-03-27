#[test_only]
module suigrove::farm_tests;
// TODO Phase 1: Unit tests
//
// Tests to write:
//   - test_create_farm: verify farm created with 4 empty plots
//   - test_plant_crop: plant on empty plot, verify state=1
//   - test_harvest_ready: fast-forward clock, harvest, verify FARM token minted
//   - test_harvest_too_early: assert ECropNotReady abort
//   - test_expand_farm: burn FARM tokens, verify plot_count increases
