/// Core game logic for SuiGrove.
///
/// Design notes:
/// - Farm is an OWNED object (not shared). This means each player's farm
///   transactions bypass global consensus — they run in parallel across
///   the network. Fast and cheap.
/// - Clock (0x6) is a shared object and IS required for consensus, but
///   since we only read it (immutable ref), it doesn't block other players.
/// - Plots are embedded in Farm's vector (not separate objects). This keeps
///   all farm state in one object — one read, one write per transaction.
module suigrove::farm;

use sui::clock::{Self, Clock};
use sui::event;
use suigrove::farm_registry::{Self, FarmRegistry};

// ===== Objects =====

/// A player's farm. Owned by the player — only they can call plant/harvest.
public struct Farm has key, store {
    id: UID,
    owner: address,
    /// Current number of plots (starts at 4, expandable to 25 in Phase 2).
    plot_count: u8,
    /// All plot slots. Length always equals plot_count.
    plots: vector<Plot>,
}

/// A single plot on the farm. Embedded in Farm.plots.
/// Has copy+drop so it can be read and updated freely within this module.
public struct Plot has store, copy, drop {
    /// Position index (0 to plot_count-1).
    index: u8,
    /// 0 = empty, 1 = planted (ready is determined client-side by comparing
    /// planted_at_ms + grow_duration_ms with current time).
    state: u8,
    /// Crop type ID matching FarmRegistry.crop_configs keys.
    crop_type: u8,
    /// Timestamp (ms) when the crop was planted. 0 when empty.
    planted_at_ms: u64,
    /// Grow duration (ms) copied from CropConfig at plant time.
    /// Cached here so harvesting doesn't need the registry for time check.
    grow_duration_ms: u64,
}

// ===== Events =====

public struct FarmCreated has copy, drop {
    farm_id: address,
    owner: address,
}

public struct CropPlanted has copy, drop {
    farm_id: address,
    plot_index: u8,
    crop_type: u8,
    planted_at_ms: u64,
    /// Pre-computed ready time. Frontend uses this for countdown timers.
    ready_at_ms: u64,
}

public struct CropHarvested has copy, drop {
    farm_id: address,
    plot_index: u8,
    crop_type: u8,
    reward_amount: u64,
}

// ===== Error codes =====

public const ENotOwner: u64        = 1;
public const EInvalidPlot: u64     = 2;
public const EPlotNotEmpty: u64    = 3;
public const EPlotNotPlanted: u64  = 4;
public const ECropNotReady: u64    = 5;
public const EMaxPlotsReached: u64 = 6;
public const EInsufficientPayment: u64 = 7;

// ===== Entry functions =====

/// Creates a new farm for the caller with 4 starter plots.
/// Each address can call this multiple times (multiple farms allowed),
/// but typically one farm per player is the intended design.
public entry fun create_farm(
    registry: &mut FarmRegistry,
    ctx: &mut TxContext
) {
    let owner = ctx.sender();
    let mut plots = vector::empty<Plot>();
    let mut i = 0u8;
    while (i < 4) {
        plots.push_back(Plot {
            index: i,
            state: 0,
            crop_type: 0,
            planted_at_ms: 0,
            grow_duration_ms: 0,
        });
        i = i + 1;
    };

    let farm = Farm {
        id: object::new(ctx),
        owner,
        plot_count: 4,
        plots,
    };
    let farm_id = object::uid_to_address(&farm.id);

    event::emit(FarmCreated { farm_id, owner });
    farm_registry::increment_total_farms(registry);
    transfer::transfer(farm, owner);
}

/// Plants a crop on an empty plot.
/// `clock` must be object 0x6 — the Sui system clock.
/// Reads crop config from registry, records the plant timestamp.
public entry fun plant(
    farm: &mut Farm,
    registry: &FarmRegistry,
    clock: &Clock,
    plot_index: u8,
    crop_type: u8,
    ctx: &mut TxContext
) {
    assert!(ctx.sender() == farm.owner, ENotOwner);
    assert!((plot_index as u64) < vector::length(&farm.plots), EInvalidPlot);

    let config = farm_registry::get_crop_config(registry, crop_type);
    let now_ms = clock::timestamp_ms(clock);
    let duration = farm_registry::grow_duration_ms(&config);

    let plot = vector::borrow_mut(&mut farm.plots, plot_index as u64);
    assert!(plot.state == 0, EPlotNotEmpty);

    plot.state = 1;
    plot.crop_type = crop_type;
    plot.planted_at_ms = now_ms;
    plot.grow_duration_ms = duration;

    let farm_id = object::uid_to_address(&farm.id);
    event::emit(CropPlanted {
        farm_id,
        plot_index,
        crop_type,
        planted_at_ms: now_ms,
        ready_at_ms: now_ms + duration,
    });
}

/// Harvests a fully grown crop and mints GROVE tokens to the player.
/// Aborts with ECropNotReady if the grow time hasn't elapsed yet.
public entry fun harvest(
    farm: &mut Farm,
    registry: &mut FarmRegistry,
    clock: &Clock,
    plot_index: u8,
    ctx: &mut TxContext
) {
    assert!(ctx.sender() == farm.owner, ENotOwner);
    assert!((plot_index as u64) < vector::length(&farm.plots), EInvalidPlot);

    let now_ms = clock::timestamp_ms(clock);
    let owner = farm.owner;
    let farm_id = object::uid_to_address(&farm.id);

    let plot = vector::borrow_mut(&mut farm.plots, plot_index as u64);
    assert!(plot.state == 1, EPlotNotPlanted);

    let ready_at = plot.planted_at_ms + plot.grow_duration_ms;
    assert!(now_ms >= ready_at, ECropNotReady);

    let crop_type = plot.crop_type;
    let config = farm_registry::get_crop_config(registry, crop_type);
    let reward = farm_registry::harvest_reward(&config);

    // Reset the plot to empty.
    plot.state = 0;
    plot.crop_type = 0;
    plot.planted_at_ms = 0;
    plot.grow_duration_ms = 0;

    // Mint GROVE tokens to the farmer.
    farm_registry::mint_grove(registry, reward, owner, ctx);

    event::emit(CropHarvested { farm_id, plot_index, crop_type, reward_amount: reward });
}

// ===== Phase 2 placeholder =====

/// Expand the farm by one plot (max 25) by burning GROVE tokens.
/// Uncomment and implement in Phase 2.
// public entry fun expand_farm(
//     farm: &mut Farm,
//     registry: &mut FarmRegistry,
//     payment: sui::coin::Coin<suigrove::farm_token::FARM_TOKEN>,
//     ctx: &mut TxContext
// ) {
//     assert!(ctx.sender() == farm.owner, ENotOwner);
//     assert!(farm.plot_count < 25, EMaxPlotsReached);
//     assert!(sui::coin::value(&payment) >= 50_000_000, EInsufficientPayment);
//     farm_registry::burn_grove(registry, payment);
//     let new_index = farm.plot_count;
//     farm.plots.push_back(Plot { index: new_index, state: 0, crop_type: 0,
//                                  planted_at_ms: 0, grow_duration_ms: 0 });
//     farm.plot_count = farm.plot_count + 1;
// }

// ===== Public read accessors (for frontend indexing) =====

public fun owner(farm: &Farm): address { farm.owner }
public fun plot_count(farm: &Farm): u8 { farm.plot_count }
public fun plots(farm: &Farm): &vector<Plot> { &farm.plots }

public fun plot_state(plot: &Plot): u8 { plot.state }
public fun plot_crop_type(plot: &Plot): u8 { plot.crop_type }
public fun plot_planted_at_ms(plot: &Plot): u64 { plot.planted_at_ms }
public fun plot_grow_duration_ms(plot: &Plot): u64 { plot.grow_duration_ms }
