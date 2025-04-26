/*
/// Module: hello_world_v2
module hello_world_v2::hello_world_v2;
*/

// For Move coding conventions, see
// https://docs.sui.io/concepts/sui-move-concepts/conventions

module hello_world_v2::hello_world {
    // import library
    use std::string;

    // create an object that contains an arbitrary string
    public struct HelloWorldObject has key, store {
        id: UID,
        text: string::String,
    }

    #[lint_allow(self_transfer)]
    public fun mint(ctx: &mut TxContext) {
        let object = HelloWorldObject {
            id: object::new(ctx),
            text: string::utf8(b"Hello World!"),
        };
        transfer::public_transfer(object, tx_context::sender(ctx));
    }
}