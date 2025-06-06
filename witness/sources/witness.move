
module witness::witness {
    use sui::object::{Self, UID};
    use sui::transfer; // <-- Added this
    use sui::tx_context::{Self, TxContext};

    public struct Guardian<phantom T: drop> has key, store {
        id: UID,
    }

    /// Module initializer is the best way to ensure that the
    /// code is called only once. With `Witness` pattern it is
    /// often the best practice.
    fun init(witness: WITNESS, ctx: &mut TxContext) {
        transfer::transfer(
            create_guardian(witness, ctx),
            tx_context::sender(ctx),
        )
    }

    /// This type is the witness resource and is intended to be used only once.
    public struct WITNESS has drop {}

    /// The first argument of this function is an actual instance of the
    /// type T with `drop` ability. It is dropped as soon as received.
    public fun create_guardian<T: drop>(_witness: T, ctx: &mut TxContext): Guardian<T> {
        Guardian { id: object::new(ctx) }
    }
}