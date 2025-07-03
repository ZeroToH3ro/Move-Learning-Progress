module fungible_tokens::managed {
    use sui::coin::{Self, Coin, TreasuryCap};
    use std::address;

    public struct MANAGED has drop {}

    fun init(witness: MANAGED, ctx: &mut TxContext) {
        let (treasury_cap, metadata) = coin::create_currency<MANAGED>(
            witness,
            2,
            b"MANAGED",
            b"MNG",
            b"",
            option::none(),
            ctx,
        );

        transfer::public_freeze_object(metadata);
        transfer::public_transfer(treasury_cap, tx_context::sender(ctx));
    }

    public fun mint(
        treasury_cap: &mut TreasuryCap<MANAGED>,
        amount: u64,
        recipient: address,
        ctx: &mut TxContext,
    ) {
        coin::mint_and_transfer(treasury_cap, amount, recipient, ctx)
    }

    // Manager can burn coins
    public fun burn(treasury_cap: &mut TreasuryCap<MANAGED>, coin: Coin<MANAGED>) {
        coin::burn(treasury_cap, coin);
    }
}