/*
/// Module: basic_data_type
module basic_data_type::basic_data_type;
*/

// For Move coding conventions, see
// https://docs.sui.io/concepts/sui-move-concepts/conventions


module basic_data_type::basic_data_type {
    use sui::object::{Self, UID};
    use sui::tx_context::{Self, TxContext};
    use std::string::{Self, String};

    public struct Person has key {
        id: UID,
        name: String,
        city: String,
        age: u8,
        date_of_birth: u8,
    }
    
    // One-time witness type for mudle initialization
    public struct BASIC_DATA_TYPE has drop {}

    // Module initializer - called once when the module is published
    fun init(_witness: BASIC_DATA_TYPE, ctx: &mut TxContext) {
        let person = Person {
            id: object::new(ctx),
            name: string::utf8(b"Default Name"),
            city: string::utf8(b"Default City"),
            age: 0,
            date_of_birth: 1,
        };

        // Transfer the person the transaction sender
        transfer::transfer(person, tx_context::sender(ctx));
    }

    public fun create_person(
        name_bytes: vector<u8>, 
        city_bytes: vector<u8>,
        age: u8, 
        date_of_birth: u8, 
        ctx: &mut TxContext
    ) {
        let person = Person {
            id: object::new(ctx),
            name: string::utf8(name_bytes),
            city: string::utf8(city_bytes),
            age: age,
            date_of_birth: date_of_birth
        };

        transfer::transfer(person, tx_context::sender(ctx));
    }
}