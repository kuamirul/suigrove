#[test_only]
module suigrove::farm_tests;

use sui::clock;
use sui::test_scenario as ts;
use sui::coin;
use suigrove::farm;
use suigrove::farm_registry::{Self, AdminCap, FarmRegistry};
use suigrove::farm_token::{Self, FARM_TOKEN};

// Test addresses
const ALICE: address = @0xA11CE;

// ===== Helpers =====

/// Sets up a FarmRegistry shared object for use in tests.
/// Returns the scenario advanced past the setup transactions.
fun setup_registry(scenario: &mut ts::Scenario) {
    // Step 1: init farm_token and farm_registry (simulates package publish)
    ts::next_tx(scenario, ALICE);
    {
        let ctx = ts::ctx(scenario);
        farm_token::init_for_testing(ctx);
        farm_registry::init_for_testing(ctx);
    };

    // Step 2: initialize_registry (simulates post-deploy admin call)
    ts::next_tx(scenario, ALICE);
    {
        let admin_cap = ts::take_from_sender<AdminCap>(scenario);
        let treasury_cap = ts::take_from_sender<coin::TreasuryCap<FARM_TOKEN>>(scenario);
        let ctx = ts::ctx(scenario);
        farm_registry::initialize_registry(&admin_cap, treasury_cap, ctx);
        ts::return_to_sender(scenario, admin_cap);
    };
}

// ===== Tests =====

#[test]
fun test_create_farm() {
    let mut scenario = ts::begin(ALICE);
    setup_registry(&mut scenario);

    // Create a farm
    ts::next_tx(&mut scenario, ALICE);
    {
        let mut registry = ts::take_shared<FarmRegistry>(&scenario);
        let ctx = ts::ctx(&mut scenario);
        farm::create_farm(&mut registry, ctx);
        ts::return_shared(registry);
    };

    // Verify the farm exists and has 4 plots
    ts::next_tx(&mut scenario, ALICE);
    {
        let farm_obj = ts::take_from_sender<farm::Farm>(&scenario);
        assert!(farm::plot_count(&farm_obj) == 4, 0);

        let plots = farm::plots(&farm_obj);
        assert!(vector::length(plots) == 4, 1);

        // All plots should be empty (state = 0)
        let mut i = 0u64;
        while (i < 4) {
            let plot = vector::borrow(plots, i);
            assert!(farm::plot_state(plot) == 0, 2);
            i = i + 1;
        };
        ts::return_to_sender(&scenario, farm_obj);
    };

    ts::end(scenario);
}

#[test]
fun test_plant_crop() {
    let mut scenario = ts::begin(ALICE);
    setup_registry(&mut scenario);

    // Create farm
    ts::next_tx(&mut scenario, ALICE);
    {
        let mut registry = ts::take_shared<FarmRegistry>(&scenario);
        let ctx = ts::ctx(&mut scenario);
        farm::create_farm(&mut registry, ctx);
        ts::return_shared(registry);
    };

    // Plant wheat (crop type 0) on plot 0
    ts::next_tx(&mut scenario, ALICE);
    {
        let mut farm_obj = ts::take_from_sender<farm::Farm>(&scenario);
        let registry = ts::take_shared<FarmRegistry>(&scenario);
        let mut clock = clock::create_for_testing(ts::ctx(&mut scenario));
        clock::set_for_testing(&mut clock, 1000); // timestamp = 1 second

        farm::plant(&mut farm_obj, &registry, &clock, 0, 0, ts::ctx(&mut scenario));

        // Verify plot 0 is now planted
        let plots = farm::plots(&farm_obj);
        let plot = vector::borrow(plots, 0);
        assert!(farm::plot_state(plot) == 1, 0);
        assert!(farm::plot_crop_type(plot) == 0, 1);
        assert!(farm::plot_planted_at_ms(plot) == 1000, 2);
        assert!(farm::plot_grow_duration_ms(plot) == 5 * 60 * 1000, 3);

        clock::destroy_for_testing(clock);
        ts::return_shared(registry);
        ts::return_to_sender(&scenario, farm_obj);
    };

    ts::end(scenario);
}

#[test]
fun test_harvest_success() {
    let mut scenario = ts::begin(ALICE);
    setup_registry(&mut scenario);

    // Create farm
    ts::next_tx(&mut scenario, ALICE);
    {
        let mut registry = ts::take_shared<FarmRegistry>(&scenario);
        farm::create_farm(&mut registry, ts::ctx(&mut scenario));
        ts::return_shared(registry);
    };

    // Plant wheat at t=0
    ts::next_tx(&mut scenario, ALICE);
    {
        let mut farm_obj = ts::take_from_sender<farm::Farm>(&scenario);
        let registry = ts::take_shared<FarmRegistry>(&scenario);
        let mut clock = clock::create_for_testing(ts::ctx(&mut scenario));
        clock::set_for_testing(&mut clock, 0);

        farm::plant(&mut farm_obj, &registry, &clock, 0, 0, ts::ctx(&mut scenario));

        clock::destroy_for_testing(clock);
        ts::return_shared(registry);
        ts::return_to_sender(&scenario, farm_obj);
    };

    // Harvest at t = 5 minutes + 1ms (crop is ready)
    ts::next_tx(&mut scenario, ALICE);
    {
        let mut farm_obj = ts::take_from_sender<farm::Farm>(&scenario);
        let mut registry = ts::take_shared<FarmRegistry>(&scenario);
        let mut clock = clock::create_for_testing(ts::ctx(&mut scenario));
        clock::set_for_testing(&mut clock, 5 * 60 * 1000 + 1); // just past grow time

        farm::harvest(&mut farm_obj, &mut registry, &clock, 0, ts::ctx(&mut scenario));

        // Plot should be empty again
        let plots = farm::plots(&farm_obj);
        let plot = vector::borrow(plots, 0);
        assert!(farm::plot_state(plot) == 0, 0);

        clock::destroy_for_testing(clock);
        ts::return_shared(registry);
        ts::return_to_sender(&scenario, farm_obj);
    };

    // Verify GROVE tokens were minted to ALICE
    ts::next_tx(&mut scenario, ALICE);
    {
        let grove_coin = ts::take_from_sender<coin::Coin<FARM_TOKEN>>(&scenario);
        // Wheat rewards 10 GROVE = 10_000_000 units (6 decimals)
        assert!(coin::value(&grove_coin) == 10_000_000, 0);
        ts::return_to_sender(&scenario, grove_coin);
    };

    ts::end(scenario);
}

#[test]
#[expected_failure(abort_code = farm::ECropNotReady)]
fun test_harvest_too_early_fails() {
    let mut scenario = ts::begin(ALICE);
    setup_registry(&mut scenario);

    // Create farm
    ts::next_tx(&mut scenario, ALICE);
    {
        let mut registry = ts::take_shared<FarmRegistry>(&scenario);
        farm::create_farm(&mut registry, ts::ctx(&mut scenario));
        ts::return_shared(registry);
    };

    // Plant at t=0
    ts::next_tx(&mut scenario, ALICE);
    {
        let mut farm_obj = ts::take_from_sender<farm::Farm>(&scenario);
        let registry = ts::take_shared<FarmRegistry>(&scenario);
        let mut clock = clock::create_for_testing(ts::ctx(&mut scenario));
        clock::set_for_testing(&mut clock, 0);
        farm::plant(&mut farm_obj, &registry, &clock, 0, 0, ts::ctx(&mut scenario));
        clock::destroy_for_testing(clock);
        ts::return_shared(registry);
        ts::return_to_sender(&scenario, farm_obj);
    };

    // Try to harvest at t=1ms — should abort with ECropNotReady
    ts::next_tx(&mut scenario, ALICE);
    {
        let mut farm_obj = ts::take_from_sender<farm::Farm>(&scenario);
        let mut registry = ts::take_shared<FarmRegistry>(&scenario);
        let mut clock = clock::create_for_testing(ts::ctx(&mut scenario));
        clock::set_for_testing(&mut clock, 1); // only 1ms elapsed

        farm::harvest(&mut farm_obj, &mut registry, &clock, 0, ts::ctx(&mut scenario));

        clock::destroy_for_testing(clock);
        ts::return_shared(registry);
        ts::return_to_sender(&scenario, farm_obj);
    };

    ts::end(scenario);
}

#[test]
#[expected_failure(abort_code = farm::ENotOwner)]
fun test_plant_by_non_owner_fails() {
    let bob: address = @0xB0B;
    let mut scenario = ts::begin(ALICE);
    setup_registry(&mut scenario);

    // ALICE creates a farm
    ts::next_tx(&mut scenario, ALICE);
    {
        let mut registry = ts::take_shared<FarmRegistry>(&scenario);
        farm::create_farm(&mut registry, ts::ctx(&mut scenario));
        ts::return_shared(registry);
    };

    // BOB tries to plant on ALICE's farm — should abort with ENotOwner
    ts::next_tx(&mut scenario, bob);
    {
        let mut farm_obj = ts::take_from_address<farm::Farm>(&scenario, ALICE);
        let registry = ts::take_shared<FarmRegistry>(&scenario);
        let mut clock = clock::create_for_testing(ts::ctx(&mut scenario));

        farm::plant(&mut farm_obj, &registry, &clock, 0, 0, ts::ctx(&mut scenario));

        clock::destroy_for_testing(clock);
        ts::return_shared(registry);
        ts::return_to_sender(&scenario, farm_obj);
    };

    ts::end(scenario);
}
