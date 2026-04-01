/// The GROVE reward token for SuiGrove.
/// Uses the One Time Witness (OTW) pattern — the struct name MUST match
/// the module name in UPPERCASE. This guarantees only one TreasuryCap
/// ever exists for this currency.
module suigrove::farm_token;

use sui::coin::{Self, TreasuryCap};
use sui::url;

/// One-time witness struct. Has `drop` so the runtime can verify
/// only one instance was ever created (at module publish time).
public struct FARM_TOKEN has drop {}

/// Called automatically when the package is published.
/// Creates the GROVE currency and sends TreasuryCap to the deployer.
/// The deployer then passes TreasuryCap to `initialize_registry`.
fun init(witness: FARM_TOKEN, ctx: &mut TxContext) {
    let (treasury_cap, metadata) = coin::create_currency<FARM_TOKEN>(
        witness,
        6,                    // 6 decimal places (1 GROVE = 1_000_000 units)
        b"GROVE",
        b"Grove Token",
        b"The in-game reward token for SuiGrove",
        option::some(url::new_unsafe_from_bytes(b"https://suigrove.vercel.app/grove-icon.png")),
        ctx
    );
    // Freeze metadata: makes it publicly readable and permanently immutable.
    transfer::public_freeze_object(metadata);
    // TreasuryCap goes to the deployer — they will pass it to initialize_registry.
    transfer::public_transfer(treasury_cap, ctx.sender());
}

// ===== Test helpers =====

#[test_only]
public fun init_for_testing(ctx: &mut TxContext) {
    init(FARM_TOKEN {}, ctx)
}

#[test_only]
public fun get_treasury_cap_for_testing(ctx: &mut TxContext): TreasuryCap<FARM_TOKEN> {
    let (treasury_cap, metadata) = coin::create_currency<FARM_TOKEN>(
        FARM_TOKEN {},
        6,
        b"GROVE",
        b"Grove Token",
        b"Test token",
        option::none(),
        ctx
    );
    transfer::public_freeze_object(metadata);
    treasury_cap
}
