module object_management::object_management {
    use sui::transfer::{public_transfer};

    public struct AddressOwnedCoin has key, store {
        id: UID,
        value: u64,
    }

    public entry fun mint_test_coin(value: u64, ctx: &mut TxContext) {
        let coin = AddressOwnedCoin { 
            id: object::new(ctx),
            value,
        };

        public_transfer(coin, tx_context::sender(ctx));
    }

    // Parameter Passing Examples
    // 1. Pass by IMMUTABLE REFERENCE (`&`): Read-only access
    // This function can only read the coin's value. It cannot modify or delete it.
    public entry fun view_coin_value(coin: &AddressOwnedCoin): u64 {
        coin.value
    }


    // 2. Pass by MUTABLE REFERENCE (`&mut`): Read-write access, no deletion/transfer
    // This function can modify the coin's value, but cannot delete or transfer the coin.
    public entry fun update_coin_value(coin: &mut AddressOwnedCoin, new_value: u64) {
        coin.value = new_value;
        // You cannot call `object::delete(coin.id)` here because you don't own `coin`.
        // You cannot call `public_transfer(coin, ...)` here because you don't own `coin`.
    }

    // 3. Pass by VALUE (`T`): Full ownership, can delete/transfer
    // This function takes ownership of the coin. It can do anything with it,
    // including deleting it.
    public entry fun transfer_coin_value(coin: AddressOwnedCoin) {
        // Object Deletion & Struct Unpacking

        // Unpack the coin object. This consumes the `coin` variable
        // This operation is ONLY allowed inside the module where `AddressOwnedCoin` is defined'
        let AddressOwnedCoin { id, value: _} = coin;

        // Call `object::delete` on the UID to remove it from chain storage.
        object::delete(id);

        // The `value: _` uses the underscore `_` to denote that we don't care about
        // the `value` field; it's consumed and dropped implicitly.
    }

    // Example of transferring a coin (takes ownership by value)
    public entry fun transfer_my_coin(coin: AddressOwnedCoin, recipient: address) {
        public_transfer(coin, recipient)
    }

    // Example of consuming a coin's value without deleting the object (for advanced understanding)
    // This would effectively leave a 'ghost' object with no data if it was a real scenario
    // but demonstrates taking ownership and unpacking without explicitly deleting the UID.
    // In Sui, if an object has `key` ability and its `UID` is not deleted, it remains on-chain.
    // So, this is generally discouraged for actual objects unless you're replacing the data.
    // We'll stick to `burn_coin` for deletion.
    /*
    public entry fun consume_coin_data(coin: AddressOwnedCoin) {
        let AddressOwnedCoin { id: _, value } = coin; // Here, `id: _` means we drop the UID.
        // `value` is now a local variable and will be dropped.
        // The object itself would remain on-chain with its UID but potentially invalid state
        // if its `value` was the only data. This is why `object::delete(id)` is essential.
    }
    */
}
