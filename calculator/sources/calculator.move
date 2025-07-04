/// Module: calculator
/// A simple calculator module for u64 integers with basic arithmetic operations
module calculator::calculator {
    
    // Error codes
    const EDivisionByZero: u64 = 0;
    const EUnderflow: u64 = 1;

    /// Calculator object to store calculation results
    public struct Calculator has key, store {
        id: UID,
        result: u64,
    }

    /// Initialize a new calculator
    public fun new(ctx: &mut TxContext): Calculator {
    í    Calculator {
            id: object::new(ctx),
            result: 0,
        }
    }

    /// Add two u64 integers
    /// Returns the sum of a and b
    public fun add(a: u64, b: u64): u64 {
        a + b
    }

    /// Subtract two u64 integers
    /// Returns the difference of a - b
    /// Aborts if b > a (underflow protection)
    public fun sub(a: u64, b: u64): u64 {
        assert!(a >= b, EUnderflow);
        a - b
    }

    /// Multiply two u64 integers
    /// Returns the product of a and b
    public fun mul(a: u64, b: u64): u64 {
        a * b
    }

    /// Divide two u64 integers
    /// Returns the quotient of a / b
    /// Aborts if b is zero (division by zero protection)
    public fun div(a: u64, b: u64): u64 {
        assert!(b != 0, EDivisionByZero);
        a / b
    }

    /// Get the current result from the calculator
    public fun get_result(calc: &Calculator): u64 {
        calc.result
    }

    /// Set the result in the calculator
    public fun set_result(calc: &mut Calculator, value: u64) {
        calc.result = value;
    }

    /// Perform addition and store result in calculator
    public fun add_and_store(calc: &mut Calculator, a: u64, b: u64) {
        calc.result = add(a, b);
    }

    /// Perform subtraction and store result in calculator
    public fun sub_and_store(calc: &mut Calculator, a: u64, b: u64) {
        calc.result = sub(a, b);
    }

    /// Perform multiplication and store result in calculator
    public fun mul_and_store(calc: &mut Calculator, a: u64, b: u64) {
        calc.result = mul(a, b);
    }

    /// Perform division and store result in calculator
    public fun div_and_store(calc: &mut Calculator, a: u64, b: u64) {
        calc.result = div(a, b);
    }

    /// Delete the calculator object
    public fun delete(calc: Calculator) {
        let Calculator { id, result: _ } = calc;
        object::delete(id);
    }
}


