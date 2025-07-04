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

    const E_INVALID_AGE: u64 = 0;
    const E_INVALID_DATE_OF_BIRTH: u64 = 1;
    const E_EMPTY_NAME: u64 = 2;

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
    // Private function
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
    // public function
    public fun create_person(
        name_bytes: vector<u8>, 
        city_bytes: vector<u8>,
        age: u8, 
        date_of_birth: u8, 
        ctx: &mut TxContext
    ) {
        // Conditional validation
        assert!(!vector::is_empty(&name_bytes), E_EMPTY_NAME);
        assert!(age >= 1 && age <=120, E_INVALID_AGE);
        assert!(date_of_birth >= 1 && date_of_birth <= 31, E_INVALID_DATE_OF_BIRTH);

        let person = Person {
            id: object::new(ctx),
            name: string::utf8(name_bytes),
            city: string::utf8(city_bytes),
            age: age,
            date_of_birth: date_of_birth
        };

        transfer::transfer(person, tx_context::sender(ctx));
    }

    public fun get_person_age(person: &Person): u8 {
        person.age
    }

    fun validate_age(age: u8): bool {
        age >= 1 && age <= 120
    }

    public fun get_person_info(person: &Person): (String, String, u8) {
        (person.name, person.city, person.age)
    }

    public fun is_adult(person: &Person): bool {
        person.age >= 18
    }

    public fun update_person_age(
        person: &mut Person,
        new_age: u8
    ) {
        assert!(validate_age(new_age), E_INVALID_AGE);
        person.age = new_age;
    }
}