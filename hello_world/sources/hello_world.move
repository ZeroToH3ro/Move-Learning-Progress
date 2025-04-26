/*
/// Module: hello_world
module hello_world::hello_world;
*/

// For Move coding conventions, see
// https://docs.sui.io/concepts/sui-move-concepts/conventions


module hello_world::hello_world {
    use std::string::String;

    public fun hello_world(): String {
        b"Hello, World!!".to_string()
    }
}