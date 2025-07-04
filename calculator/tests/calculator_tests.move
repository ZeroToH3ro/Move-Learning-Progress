#[test_only]
module calculator::calculator_tests {
    use calculator::calculator;

    #[test]
    fun test_add() {
        // Test basic addition
        assert!(calculator::add(5, 3) == 8, 0);
        assert!(calculator::add(0, 0) == 0, 0);
        assert!(calculator::add(100, 200) == 300, 0);
        assert!(calculator::add(1, 999) == 1000, 0);
    }

    #[test]
    fun test_sub() {
        // Test basic subtraction
        assert!(calculator::sub(10, 3) == 7, 0);
        assert!(calculator::sub(5, 5) == 0, 0);
        assert!(calculator::sub(1000, 1) == 999, 0);
        assert!(calculator::sub(50, 25) == 25, 0);
    }

    #[test]
    fun test_mul() {
        // Test basic multiplication
        assert!(calculator::mul(5, 3) == 15, 0);
        assert!(calculator::mul(0, 100) == 0, 0);
        assert!(calculator::mul(1, 42) == 42, 0);
        assert!(calculator::mul(10, 10) == 100, 0);
    }

    #[test]
    fun test_div() {
        // Test basic division
        assert!(calculator::div(15, 3) == 5, 0);
        assert!(calculator::div(100, 10) == 10, 0);
        assert!(calculator::div(7, 2) == 3, 0); // Integer division
        assert!(calculator::div(42, 1) == 42, 0);
    }

    #[test]
    #[expected_failure(abort_code = 1)]
    fun test_sub_underflow() {
        // This should fail because 3 - 5 would underflow
        calculator::sub(3, 5);
    }

    #[test]
    #[expected_failure(abort_code = 0)]
    fun test_div_by_zero() {
        // This should fail because division by zero is not allowed
        calculator::div(10, 0);
    }

    #[test]
    fun test_edge_cases() {
        // Test with maximum u64 values where possible
        let max_val = 18446744073709551615u64; // 2^64 - 1
        
        // Test addition with 0
        assert!(calculator::add(max_val, 0) == max_val, 0);
        
        // Test subtraction with 0
        assert!(calculator::sub(max_val, 0) == max_val, 0);
        
        // Test multiplication with 0
        assert!(calculator::mul(max_val, 0) == 0, 0);
        
        // Test multiplication with 1
        assert!(calculator::mul(max_val, 1) == max_val, 0);
        
        // Test division with 1
        assert!(calculator::div(max_val, 1) == max_val, 0);
        
        // Test division of same numbers
        assert!(calculator::div(max_val, max_val) == 1, 0);
    }

    #[test]
    fun test_calculator_object() {
        use sui::tx_context;
        
        // Create a dummy context for testing
        let ctx = &mut tx_context::dummy();
        
        // Create a new calculator
        let mut calc = calculator::new(ctx);
        
        // Test initial state
        assert!(calculator::get_result(&calc) == 0, 0);
        
        // Test add_and_store
        calculator::add_and_store(&mut calc, 10, 5);
        assert!(calculator::get_result(&calc) == 15, 0);
        
        // Test sub_and_store
        calculator::sub_and_store(&mut calc, 20, 8);
        assert!(calculator::get_result(&calc) == 12, 0);
        
        // Test mul_and_store
        calculator::mul_and_store(&mut calc, 6, 7);
        assert!(calculator::get_result(&calc) == 42, 0);
        
        // Test div_and_store
        calculator::div_and_store(&mut calc, 84, 2);
        assert!(calculator::get_result(&calc) == 42, 0);
        
        // Test set_result
        calculator::set_result(&mut calc, 100);
        assert!(calculator::get_result(&calc) == 100, 0);
        
        // Clean up
        calculator::delete(calc);
    }
}
