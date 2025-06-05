module 0x0::coin_vault_ballot {
    use sui::tx_context::{Self, TxContext};
    use sui::transfer::{Self, public_transfer, freeze_object, share_object};
    use sui::object::{Self, UID, ID};
    use sui::dynamic_field::{Self, Field};

    // === Owned by an Address ===

    // The Coin that can be a top-level object (e.g., in someone's wallet)
    public struct AddressOwnedCoin has key, store {
        id: UID,
        value: u64,
    }

    // Function to mint a new AddressOwnedCoin, owned by the sender
    public entry fun mint_address_owned_coin(value: u64, ctx: &mut TxContext) {
        let coin = AddressOwnedCoin {
            id: object::new(ctx),
            value,
        };
        public_transfer(coin, tx_context::sender(ctx));
    }

    // Function to get value from AddressOwnedCoin
    public fun get_address_owned_coin_value(coin: &AddressOwnedCoin): u64 {
        coin.value
    }


    // === Owned by an Object (Child Object) ===

    // This is the Coin type that will be stored *inside* a Vault.
    // Notice it DOES NOT have the `key` ability, only `store` and `drop`.
    // It does not have its own `UID` field because it's not a top-level object.
    // We'll use a `u64` for an internal ID within the vault for clarity.
    public struct VaultCoin has store, drop { // Removed `key` here
        // id: UID, // Removed UID, as it's no longer a top-level object
        internal_id: u64, // An ID for this coin *within the vault*
        value: u64,
    }

    // A Vault that can hold VaultCoins. This will be the "parent" object.
    public struct Vault has key, store {
        id: UID,
        owner_name: vector<u8>,
        next_coin_id_counter: u64, // For generating unique keys for child coins
    }

    // Function to create a new Vault (owned by an address initially)
    public entry fun create_vault(name: vector<u8>, ctx: &mut TxContext) {
        let vault = Vault {
            id: object::new(ctx),
            owner_name: name,
            next_coin_id_counter: 0,
        };
        public_transfer(vault, tx_context::sender(ctx));
    }

    // Function to deposit a *value* into a Vault, creating a new VaultCoin as a child
    // This function takes a `u64` value, not an existing `AddressOwnedCoin`.
    public entry fun deposit_value_to_vault(vault: &mut Vault, value_to_deposit: u64) {
        let new_vault_coin = VaultCoin {
            internal_id: vault.next_coin_id_counter,
            value: value_to_deposit,
        };
        // Use the internal counter as the key for the dynamic field
        let key = vault.next_coin_id_counter;
        dynamic_field::add(&mut vault.id, key, new_vault_coin);

        vault.next_coin_id_counter = vault.next_coin_id_counter + 1;
    }

    // Function to withdraw a VaultCoin from a Vault
    // This function takes the *internal_id* used as the dynamic field key.
    public entry fun withdraw_vault_coin(vault: &mut Vault, internal_coin_id: u64, ctx: &mut TxContext) {
        // dynamic_field::remove takes the parent object and the key to remove the child.
        let vault_coin: VaultCoin = dynamic_field::remove(&mut vault.id, internal_coin_id);

        // We can't directly transfer a VaultCoin back to an address
        // because it doesn't have `key`.
        // We typically convert it back into an AddressOwnedCoin or similar,
        // or just 'drop' it if its purpose was internal.
        // For demonstration, let's just create a new AddressOwnedCoin with its value.
        let new_address_owned_coin = AddressOwnedCoin {
            id: object::new(ctx),
            value: vault_coin.value,
        };
        // The `vault_coin` itself is implicitly dropped here since it has `drop`.

        public_transfer(new_address_owned_coin, tx_context::sender(ctx));
    }

    // Function to get the value of a specific VaultCoin by its internal ID
    public fun get_vault_coin_value(vault: &Vault, internal_coin_id: u64): u64 {
        let coin: &VaultCoin = dynamic_field::borrow(&vault.id, internal_coin_id);
        coin.value
    }


    // === Shared Immutable Objects ===

    // A simple Ballot object. We want this to be immutable once created.
    public struct Ballot has key, store {
        id: UID,
        question: vector<u8>,
        options: vector<vector<u8>>,
    }

    // Function to create a Ballot and immediately make it immutable
    public entry fun create_immutable_ballot(
        question: vector<u8>,
        options: vector<vector<u8>>,
        ctx: &mut TxContext
    ) {
        let ballot = Ballot {
            id: object::new(ctx),
            question,
            options,
        };
        freeze_object(ballot);
    }

    // Function to read data from a shared immutable ballot (no mutation allowed)
    public fun get_ballot_question(ballot: &Ballot): vector<u8> {
        ballot.question
    }

    // === Shared Mutable Objects ===

    // A Poll object where anyone can vote.
    public struct Poll has key, store {
        id: UID,
        topic: vector<u8>,
        yes_votes: u64,
        no_votes: u64,
    }

    // Function to create a Poll and make it shared mutable
    public entry fun create_shared_poll(topic: vector<u8>, ctx: &mut TxContext) {
        let poll = Poll {
            id: object::new(ctx),
            topic,
            yes_votes: 0,
            no_votes: 0,
        };
        share_object(poll);
    }

    // Function to vote 'Yes' on a shared Poll
    public entry fun vote_yes(poll: &mut Poll) {
        poll.yes_votes = poll.yes_votes + 1;
    }

    // Function to vote 'No' on a shared Poll
    public entry fun vote_no(poll: &mut Poll) {
        poll.no_votes = poll.no_votes + 1;
    }

    // Function to read poll results (anyone can read)
    public fun get_poll_results(poll: &Poll): (u64, u64) {
        (poll.yes_votes, poll.no_votes)
    }

    // Helper functions (for demonstration and clarity)
    public fun get_vault_owner_name(vault: &Vault): vector<u8> {
        vault.owner_name
    }
}