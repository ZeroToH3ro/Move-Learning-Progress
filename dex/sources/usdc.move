module dex::usdc {
    use std::option;
    use sui::url;
    use sui::coin;
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};

    // ** Structs

    // One Time Witness to create a Current in Sui
    // This struct has the drop ability so it cannot be transferred nor stored. 
    // It allows the Network to know it is a unique type

    public struct USDC has drop {}

    public struct UsdcData has store {
        dummy: bool
    }

    fun init(witness: USDC, ctx: &mut TxContext) {
        // We call the create_currency
        // Creating a currency requires a one-time witness to ensure it is a unique coin
        // Only the holder of the TreasuryCap is allowed to mint and burn this coin
        // Metadata holds all the information about the coin, so other applications query it
        let (treasury_cap, metadata) = coin::create_currency<USDC>(
            witness,
            9,
            b"USDC",
            b"USDC Coin",
            b"A stable coin issued by Circle",
            option::some(url::new_unsafe_from_bytes(b"https://s3.coinmarketcap.com/static-gravity/image/5a8229787b5e4c809b5914eef709b59a.png")),
            ctx
        );
        // We send the treasury capability to the deployer
        transfer::public_transfer(treasury_cap, tx_context::sender(ctx));
        // Objects defined in different modules need to use the public_transfer function
        transfer::public_share_object(metadata);
    }

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(USDC {}, ctx);
    }
}