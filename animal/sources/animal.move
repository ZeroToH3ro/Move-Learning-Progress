module animal::animal {
    use std::string::{Self, String};
    use sui::object::UID;

    // Define the AnimeObject struct with required properties
    public struct AnimeObject has key, store {
        id: UID,
        name: String,
        no_of_legs: u8,
        favorite_food: String,
    }

    // Constructor function to create a new AnimeObject
    #[allow(lint(self_transfer))]
    public fun create_anime_object(
        name: vector<u8>,
        no_of_legs: u8,
        favorite_food: vector<u8>,
        ctx: &mut TxContext
    ) {
        let anime_object = AnimeObject {
            id: object::new(ctx),
            name: string::utf8(name),
            no_of_legs,
            favorite_food: string::utf8(favorite_food),
        };
        
        // Transfer ownership to the sender
        transfer::transfer(anime_object, tx_context::sender(ctx));
    }

    // Getter functions for the properties
    public fun get_name(anime_object: &AnimeObject): String {
        anime_object.name
    }

    public fun get_no_of_legs(anime_object: &AnimeObject): u8 {
        anime_object.no_of_legs
    }

    public fun get_favorite_food(anime_object: &AnimeObject): String {
        anime_object.favorite_food
    }
}


