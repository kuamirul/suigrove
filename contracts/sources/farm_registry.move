/// Shared singleton registry for SuiGrove.
/// Holds the TreasuryCap (mint authority) and crop configuration table.
/// Only the game's own Move functions can mint GROVE tokens — no human
/// can call mint directly because TreasuryCap is locked inside this object.
module suigrove::farm_registry;

use sui::coin::{Self, TreasuryCap};
use sui::table::{Self, Table};
use suigrove::farm_token::FARM_TOKEN;

// ===== Objects =====

/// Shared object — exists as a singleton on-chain.
/// All game transactions that need to read crop configs or mint tokens
/// must pass this object.
public struct FarmRegistry has key {
    id: UID,
    /// Locked mint authority — only package-internal functions can use this.
    treasury_cap: TreasuryCap<FARM_TOKEN>,
    /// Total number of farms ever created. Used for leaderboard/stats.
    total_farms: u64,
    /// Crop type ID (u8) → CropConfig. Set at initialize time, extendable by admin.
    crop_configs: Table<u8, CropConfig>,
}

/// Configuration for one crop type. Stored in the registry table.
public struct CropConfig has store, copy, drop {
    /// How long the crop takes to fully grow, in milliseconds.
    grow_duration_ms: u64,
    /// Amount of GROVE tokens (with 6 decimals) rewarded on harvest.
    harvest_reward: u64,
}

/// Admin capability — owned by the deployer.
/// Required to call privileged functions (add_crop_type, etc.).
/// Keep this safe — losing it means you can't add new crop types.
public struct AdminCap has key, store {
    id: UID,
}

// ===== Error codes =====

const EInvalidCropType: u64 = 0;
const ECropTypeAlreadyExists: u64 = 1;

// ===== Init =====

/// Called automatically on package publish.
/// Creates the AdminCap and sends it to the deployer.
fun init(ctx: &mut TxContext) {
    transfer::transfer(AdminCap { id: object::new(ctx) }, ctx.sender());
}

// ===== Admin entry functions =====

/// Called once after publish to create the shared FarmRegistry.
/// Pass the TreasuryCap received from the publish transaction.
/// Seeds the initial three crop types.
public entry fun initialize_registry(
    _: &AdminCap,
    treasury_cap: TreasuryCap<FARM_TOKEN>,
    ctx: &mut TxContext
) {
    let mut registry = FarmRegistry {
        id: object::new(ctx),
        treasury_cap,
        total_farms: 0,
        crop_configs: table::new(ctx),
    };

    // Crop 0: Wheat — fast and low reward (good for learning)
    table::add(&mut registry.crop_configs, 0u8, CropConfig {
        grow_duration_ms: 5 * 60 * 1000,   // 5 minutes
        harvest_reward:   10_000_000,        // 10 GROVE
    });
    // Crop 1: Corn — medium effort, medium reward
    table::add(&mut registry.crop_configs, 1u8, CropConfig {
        grow_duration_ms: 15 * 60 * 1000,   // 15 minutes
        harvest_reward:   35_000_000,        // 35 GROVE
    });
    // Crop 2: Pumpkin — long wait, high reward
    table::add(&mut registry.crop_configs, 2u8, CropConfig {
        grow_duration_ms: 60 * 60 * 1000,   // 60 minutes
        harvest_reward:   200_000_000,       // 200 GROVE
    });

    transfer::share_object(registry);
}

/// Admin: add a new crop type after launch (e.g., seasonal crops).
public entry fun add_crop_type(
    _: &AdminCap,
    registry: &mut FarmRegistry,
    crop_type: u8,
    grow_duration_ms: u64,
    harvest_reward: u64,
) {
    assert!(
        !table::contains(&registry.crop_configs, crop_type),
        ECropTypeAlreadyExists
    );
    table::add(&mut registry.crop_configs, crop_type, CropConfig {
        grow_duration_ms,
        harvest_reward,
    });
}

// ===== Package-internal functions (callable by farm.move only) =====

/// Returns a copy of the crop config for the given type.
/// Aborts if the crop type doesn't exist.
public(package) fun get_crop_config(registry: &FarmRegistry, crop_type: u8): CropConfig {
    assert!(table::contains(&registry.crop_configs, crop_type), EInvalidCropType);
    *table::borrow(&registry.crop_configs, crop_type)
}

/// Accessor: grow duration in ms from a CropConfig value.
public(package) fun grow_duration_ms(config: &CropConfig): u64 {
    config.grow_duration_ms
}

/// Accessor: harvest reward amount from a CropConfig value.
public(package) fun harvest_reward(config: &CropConfig): u64 {
    config.harvest_reward
}

/// Mints GROVE tokens to `recipient`. Called by farm::harvest.
public(package) fun mint_grove(
    registry: &mut FarmRegistry,
    amount: u64,
    recipient: address,
    ctx: &mut TxContext
) {
    coin::mint_and_transfer(&mut registry.treasury_cap, amount, recipient, ctx);
}

/// Burns GROVE tokens. Called by farm::expand_farm (Phase 2).
public(package) fun burn_grove(
    registry: &mut FarmRegistry,
    coin: sui::coin::Coin<FARM_TOKEN>,
) {
    coin::burn(&mut registry.treasury_cap, coin);
}

/// Increments total farms counter. Called by farm::create_farm.
public(package) fun increment_total_farms(registry: &mut FarmRegistry) {
    registry.total_farms = registry.total_farms + 1;
}

/// Read total farms (for leaderboard/frontend display).
public fun total_farms(registry: &FarmRegistry): u64 {
    registry.total_farms
}

// ===== Test helpers =====

#[test_only]
public fun init_for_testing(ctx: &mut TxContext) {
    init(ctx)
}

#[test_only]
public fun create_registry_for_testing(
    treasury_cap: TreasuryCap<FARM_TOKEN>,
    ctx: &mut TxContext
): FarmRegistry {
    let mut registry = FarmRegistry {
        id: object::new(ctx),
        treasury_cap,
        total_farms: 0,
        crop_configs: table::new(ctx),
    };
    table::add(&mut registry.crop_configs, 0u8, CropConfig {
        grow_duration_ms: 5 * 60 * 1000,
        harvest_reward:   10_000_000,
    });
    table::add(&mut registry.crop_configs, 1u8, CropConfig {
        grow_duration_ms: 15 * 60 * 1000,
        harvest_reward:   35_000_000,
    });
    table::add(&mut registry.crop_configs, 2u8, CropConfig {
        grow_duration_ms: 60 * 60 * 1000,
        harvest_reward:   200_000_000,
    });
    registry
}
