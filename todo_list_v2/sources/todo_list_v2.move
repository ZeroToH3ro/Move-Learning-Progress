module todo_list_v2::todo_list {
    // Import necessary modules
    use std::string::{Self, String}; // Import String and the module itself for potential static calls
    use std::vector; // Import the vector module
    use sui::object::{Self, UID}; // Import UID and the object module
    use sui::tx_context::{Self, TxContext}; // Import TxContext

    // Unused import - remove this line
    // use sui::nitro_attestation::index;

    public struct TodoList has key, store {
        id: UID,
        items: vector<String>
    }

    // Create a new todo list
    // No changes needed here, assuming object::new is correct
    public entry fun new(ctx: &mut TxContext) {
        // Create the list
        let list = TodoList {
            id: object::new(ctx),
            items: vector::empty<String>() // Use vector::empty for clarity
        };
        // Transfer the new object to the sender implicitly (typical for entry funcs creating objects)
        // Or explicitly: transfer::public_transfer(list, tx_context::sender(ctx));
        // For shared objects, use transfer::share_object(list);
        // Let's assume it should be owned by the creator
        transfer::public_transfer(list, tx_context::sender(ctx));
    }

    // Add a todo item to the list
    // (Added this function for completeness, as it's usually needed)
    public entry fun add(list: &mut TodoList, item: String) {
        vector::push_back(&mut list.items, item);
    }

    // Remove a todo item from the list by index and return it
    // Corrected the function call and added explicit return
    public entry fun remove(list: &mut TodoList, index: u64): String {
        // Use the correct vector module call syntax
        // Explicitly return the result
        return vector::remove(&mut list.items, index)
    }

    // Delete the list.
    // Assumes String has drop, so vector<String> has drop.
    // If String lacks drop, this function would need manual cleanup.
    public entry fun delete(list: TodoList) {
        let TodoList { id, items: _ } = list; // items vector is implicitly dropped here
        object::delete(id); // Delete the object metadata
    }

    // Get the number of items in the list.
    // (Read-only functions don't usually need to be 'entry')
    public fun length(list: &TodoList): u64 {
        // Use the correct vector module call syntax for consistency
        vector::length(&list.items)
    }

    // Get an immutable reference to an item (view function)
    // (Added for completeness)
    public fun borrow_item(list: &TodoList, index: u64): &String {
        vector::borrow(&list.items, index)
    }

    // Get a copy of an item (view function)
    // Requires String to have the 'copy' ability
    public entry fun get_item(list: &TodoList, index: u64): String {
        *vector::borrow(&list.items, index)
    }

    public entry fun get_all_items(list: &TodoList): vector<String> {
        // Vectors (if their elements are copyable) are typically copied when returned by value.
        list.items
    }
}
