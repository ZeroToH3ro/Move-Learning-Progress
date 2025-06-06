module generics_example::generics_example {
    use sui::object::{Self, UID, ID};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer::{Self, public_transfer};

    public struct Box<T: store> has key, store {
        id: UID,
        value: T,
    }

    public struct SimpleBox has key, store {
        id: UID,
        value: u8,
    }

    public struct PhantomBox<phantom T: drop> has key {
        id: UID,
    }

    #[lint_allow(self_transfer)]
    public fun create_box<T: store>(value: T, ctx: &mut TxContext) {
        transfer::transfer(Box<T> { id: object::new(ctx), value }, tx_context::sender(ctx))
    }

    #[lint_allow(self_transfer)]
    public fun create_simple_box(value: u8, ctx: &mut TxContext) {
        transfer::transfer(SimpleBox { id: object::new(ctx), value }, tx_context::sender(ctx))
    }

    public fun create_phantom_box<T: drop>(_value: T, ctx: &mut TxContext) {
        transfer::transfer(PhantomBox<T> { id: object::new(ctx) }, tx_context::sender(ctx))
    }
}