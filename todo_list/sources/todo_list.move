/*
/// Module: todo_list
module todo_list::todo_list;
*/

// For Move coding conventions, see
// https://docs.sui.io/concepts/sui-move-concepts/conventions
module todo_list::todo_list {
    use std::string::String;
    use sui::nitro_attestation::index;

    public struct TodoList has key, store {
        id: UID,
        items: vector<String>
    }

    // Create a new todo list
    public fun new(ctx: &mut TxContext): TodoList {
        let list = TodoList {
            id: object::new(ctx),
            items: vector[]
        };

        return list
    }

    // Remove a todo item from the list by index
    public fun remove(list: &mut TodoList, index: u64): String {
        list.items.remove(index)
    }

    // Delete the list and the capability to manage it.
    public fun delete(list: TodoList) {
        let TodoList { id, items: _ } = list;
        id.delete()
    }

    // Get the number of items in the list.
    public fun length(list: &TodoList): u64 {
        list.items.length()
    }
}

