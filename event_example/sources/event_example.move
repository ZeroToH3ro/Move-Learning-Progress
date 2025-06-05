module event_example::event_example {
    use sui::tx_context::{Self, TxContext};
    use sui::transfer::{Self, public_transfer};
    use sui::object::{Self, UID, ID};
    use sui::event;
    use std::address; // Import the event module!


    public struct MyTestCoin has key, store {
        id: UID,
        value: u64,
    }

    // === Define Custom Event Structs ===
    public struct CoinMintedEvent has copy, drop {
        coin_id: ID,
        value: u64,
        minter: address,
    }

    public struct CoinDepositedEvent has copy, drop {
        coin_id: ID,
        value: u64,
        depositor: address,
    }

    public struct CoinWithdrawnEvent has copy, drop {
        coin_id: ID,
        value: u64,
        withdrawer: address,
    }

     public struct CoinBurnedEvent has copy, drop {
        coin_id: ID,       // The ID of the coin that was burned
        value: u64,        // The value of the burned coin
        burner: address,   // The address that burned the coin
    }

    // === Functions that Emit Events ===

    // Mint a new MyTestCoin
    public entry fun mint_my_coin(value: u64, ctx: &mut TxContext) {
        let coin = MyTestCoin {
            id: object::new(ctx),
            value,
        };

        // Emit CoinMintedEvent
        event::emit(CoinMintedEvent {
            // Use object::id(&coin.id) to get a copyable ID from the UID for the event
            coin_id: object::uid_to_inner(&coin.id),
            value: coin.value,
            minter: tx_context::sender(ctx),
        });

        public_transfer(coin, tx_context::sender(ctx));
    }

    // Simulate depositing a coin (e.g., into a contract's internal state or another object)
    // For simplicity, this will just consume the coin but emit an event.
    public entry fun deposit_my_coin(coin: MyTestCoin, ctx: &mut TxContext) {
        // Unpack the coin to get its ID and value for the event
        let MyTestCoin { id, value } = coin;

        // Emit CoinDepositedEvent
        event::emit(CoinDepositedEvent {
            coin_id: object::uid_to_inner(&id), // Use object::id(&id) here as well
            value,
            depositor: tx_context::sender(ctx),
        });

        // In a real scenario, you would store this coin or its value somewhere
        // For this example, the coin is implicitly dropped/burned since its UID is not deleted,
        // and its value is consumed. This is simplified for event demonstration.
        // A more complete system would move the UID into a container or delete it.
        object::delete(id); // Delete the UID to fully remove the object
    }

    // Simulate withdrawing a coin (e.g., creating a new coin to give to the user)
    public entry fun withdraw_my_coin(value: u64, ctx: &mut TxContext) {
        let new_coin = MyTestCoin {
            id: object::new(ctx),
            value,
        };

        // Emit CoinWithdrawnEvent
        event::emit(CoinWithdrawnEvent {
            coin_id: object::uid_to_inner(&new_coin.id),
            value: new_coin.value,
            withdrawer: tx_context::sender(ctx),
        });

        public_transfer(new_coin, tx_context::sender(ctx));
    }

    // Burn an existing MyTestCoin
    public entry fun burn_my_coin(coin: MyTestCoin, ctx: &mut TxContext) {
        let MyTestCoin { id, value } = coin;

        // Emit CoinBurnedEvent
        event::emit(CoinBurnedEvent {
            coin_id: object::uid_to_inner(&id),
            value,
            burner: tx_context::sender(ctx),
        });

        object::delete(id); // Delete the object from chain storage
    }

    // Helper function to view coin value
    public fun view_coin_value(coin: &MyTestCoin): u64 {
        coin.value
    }
}