module dex::dex {
    use std::type_name::{Self, TypeName};
    use std::option::{Self, Option};
    use std::vector;
    use sui::coin::{Self, Coin, TreasuryCap};
    use sui::balance::{Self, Supply};
    use sui::object::{Self, UID};
    use sui::clock::Clock;
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;
    use sui::table::{Self, Table};
    use sui::dynamic_field as df;
    
    use deepbook::pool::{Self as pool_v3, Pool};
    use deepbook::balance_manager::{Self as bm, BalanceManager, TradeProof};
    
    use dex::eth::{ETH, EthData};
    use dex::usdc::{USDC, UsdcData};

    const CLIENT_ID: u64 = 122227;
    const FLOAT_SCALING: u64 = 1_000_000_000; 

    const EAlreadyMintedThisEpoch: u64 = 0;
    const EAccountNotInitialized: u64 = 1;
    const EPoolAlreadyExists: u64 = 3;
    const EInvalidPoolParameters: u64 = 4;

    public struct DEX has drop {}

    public struct Data<phantom CoinType> has store {
        cap: TreasuryCap<CoinType>,
        faucet_lock: Table<address, u64>
    }

    public struct PoolInfo has store, copy, drop {
        tick_size: u64,
        lot_size: u64,
        min_size: u64,
        creator: address,
        timestamp: u64,
        is_active: bool,
    }

    public struct Storage has key {
        id: UID,
        dex_supply: Supply<DEX>,
        swaps: Table<address, u64>,
        balance_manager: Option<BalanceManager>,
        client_id: u64,
        pool_info: Option<PoolInfo>,
        pending_pools: vector<PoolInfo>,
    }


    #[allow(unused_function)]
    fun init(witness: DEX, ctx: &mut TxContext) { 
        let (treasury_cap, metadata) = coin::create_currency<DEX>(
                    witness, 
                    9, 
                    b"DEX",
                    b"DEX Coin", 
                    b"Coin of SUI DEX", 
                    option::none(), 
                    ctx
            );
        
        transfer::public_freeze_object(metadata);

        transfer::share_object(Storage {
            id: object::new(ctx), 
            dex_supply: coin::treasury_into_supply(treasury_cap), 
            swaps: table::new(ctx),
            balance_manager: option::none(),
            client_id: CLIENT_ID,
            pool_info: option::none(),
            pending_pools: vector::empty(),
        });
    }

    //TODO: Implement pool v3
    public fun create_pool_info_v3(
        self: &mut Storage,
        tick_size: u64,
        lot_size: u64,
        min_size: u64,
        ctx: &mut TxContext
    ) {
        // Validate parameters
        assert!(tick_size > 0, EInvalidPoolParameters);
        assert!(lot_size > 0, EInvalidPoolParameters);
        assert!(min_size > 0, EInvalidPoolParameters);
        
        // Check if pool already exists
        assert!(option::is_none(&self.pool_info), EPoolAlreadyExists);
        
        let sender = tx_context::sender(ctx);
        let timestamp = tx_context::epoch_timestamp_ms(ctx);
        
        // Create pool info
        let pool_info = PoolInfo {
            tick_size,
            lot_size,
            min_size,
            creator: sender,
            timestamp,
            is_active: false, // Will be set to true when actual pool is created
        };
        
        // Store as the main pool info
        option::fill(&mut self.pool_info, pool_info);
        
        // Also add to pending pools list for tracking
        vector::push_back(&mut self.pending_pools, pool_info);
    }

    // Add utility functions for pool management
    public fun get_pool_info(self: &Storage): Option<PoolInfo> {
        self.pool_info
    }

    public fun is_pool_created(self: &Storage): bool {
        if (option::is_some(&self.pool_info)) {
            let pool_info = option::borrow(&self.pool_info);
            pool_info.is_active
        } else {
            false
        }
    }

    public fun get_pool_parameters(self: &Storage): (u64, u64, u64) {
        assert!(option::is_some(&self.pool_info), EAccountNotInitialized);
        let pool_info = option::borrow(&self.pool_info);
        (pool_info.tick_size, pool_info.lot_size, pool_info.min_size)
    }

    public fun get_pool_creator(self: &Storage): address {
        assert!(option::is_some(&self.pool_info), EAccountNotInitialized);
        let pool_info = option::borrow(&self.pool_info);
        pool_info.creator
    }

    public fun get_pending_pools_count(self: &Storage): u64 {
        vector::length(&self.pending_pools)
    }

    // Function to mark pool as active (would be called when actual pool is created)
    public fun activate_pool(self: &mut Storage, ctx: &mut TxContext) {
        assert!(option::is_some(&self.pool_info), EAccountNotInitialized);
        let pool_info = option::borrow_mut(&mut self.pool_info);
        pool_info.is_active = true;
        pool_info.timestamp = tx_context::epoch_timestamp_ms(ctx);
    }

    // Entry function for easy pool creation
    public fun entry_create_pool_info_v3(
        self: &mut Storage,
        tick_size: u64,
        lot_size: u64,
        min_size: u64,
        ctx: &mut TxContext
    ) {
        create_pool_info_v3(self, tick_size, lot_size, min_size, ctx);
    }

    // Advanced function to create multiple pool configurations
    public fun create_multiple_pool_configs(
        self: &mut Storage,
        tick_sizes: vector<u64>,
        lot_sizes: vector<u64>,
        min_sizes: vector<u64>,
        ctx: &mut TxContext
    ) {
        assert!(vector::length(&tick_sizes) == vector::length(&lot_sizes), EInvalidPoolParameters);
        assert!(vector::length(&lot_sizes) == vector::length(&min_sizes), EInvalidPoolParameters);
        
        let len = vector::length(&tick_sizes);
        let mut i = 0;
        
        while (i < len) {
            let tick_size = *vector::borrow(&tick_sizes, i);
            let lot_size = *vector::borrow(&lot_sizes, i);
            let min_size = *vector::borrow(&min_sizes, i);
            
            let pool_info = PoolInfo {
                tick_size,
                lot_size,
                min_size,
                creator: tx_context::sender(ctx),
                timestamp: tx_context::epoch_timestamp_ms(ctx),
                is_active: false,
            };
            
            vector::push_back(&mut self.pending_pools, pool_info);
            i = i + 1;
        };
    }

    // Function to prepare for actual DeepBook V3 pool creation
    public fun prepare_pool_creation_data(self: &Storage): (u64, u64, u64, address) {
        assert!(option::is_some(&self.pool_info), EAccountNotInitialized);
        let pool_info = option::borrow(&self.pool_info);
        (pool_info.tick_size, pool_info.lot_size, pool_info.min_size, pool_info.creator)
    }

    // Function to simulate pool creation with event emission
    public struct PoolCreationEvent has copy, drop {
        creator: address,
        tick_size: u64,
        lot_size: u64,
        min_size: u64,
        timestamp: u64,
    }

    public fun emit_pool_creation_event(self: &Storage) {
        if (option::is_some(&self.pool_info)) {
            let pool_info = option::borrow(&self.pool_info);
            sui::event::emit(PoolCreationEvent {
                creator: pool_info.creator,
                tick_size: pool_info.tick_size,
                lot_size: pool_info.lot_size,
                min_size: pool_info.min_size,
                timestamp: pool_info.timestamp,
            });
        };
    }

    // Validation function for pool parameters
    public fun validate_pool_parameters(tick_size: u64, lot_size: u64, min_size: u64): bool {
        // Add your validation logic here
        // Example validations:
        tick_size > 0 && tick_size <= 1000 &&
        lot_size > 0 && lot_size <= 1000000 &&
        min_size > 0 && min_size <= lot_size
    }

    // Function to estimate pool creation cost (for future integration)
    public fun estimate_pool_creation_cost(tick_size: u64, lot_size: u64, min_size: u64): u64 {
        // This would calculate the cost based on DeepBook V3 requirements
        // For now, return a base cost
        let base_cost = 1000; // Base cost in MIST
        let complexity_factor = (tick_size + lot_size + min_size) / 100;
        base_cost + complexity_factor
    }

    public fun is_balance_manager_initialized(self: &Storage): bool {
        option::is_some(&self.balance_manager)
    }

    public fun get_balance_manager(self: &Storage): &BalanceManager {
        assert!(option::is_some(&self.balance_manager), EAccountNotInitialized);
        option::borrow(&self.balance_manager)
    }

    fun get_balance_manager_mut(self: &mut Storage): &mut BalanceManager {
        assert!(option::is_some(&self.balance_manager), EAccountNotInitialized);
        option::borrow_mut(&mut self.balance_manager)
    }

    // V3 Balance Manager initialization
    public fun init_balance_manager(self: &mut Storage, ctx: &mut TxContext) {
        assert!(option::is_none(&self.balance_manager), 0);
        let balance_manager = bm::new(ctx);
        option::fill(&mut self.balance_manager, balance_manager);
    }

    // V3 Market order implementation - Simplified version
    public fun place_market_order_v3(
        self: &mut Storage,
        _pool: &mut Pool<ETH, USDC>,
        quantity: u64,
        is_bid: bool,
        base_coin: Coin<ETH>,
        quote_coin: Coin<USDC>,
        _clock: &Clock,
        ctx: &mut TxContext,    
    ): (Coin<ETH>, Coin<USDC>, Coin<DEX>) {
        let sender = tx_context::sender(ctx);  
        let mut dex_coin = coin::zero(ctx);

        // Track swaps for rewards
        if (table::contains(&self.swaps, sender)) {
            let total_swaps = table::borrow_mut(&mut self.swaps, sender);
            let new_total_swap = *total_swaps + 1;
            *total_swaps = new_total_swap;

            if ((new_total_swap % 2) == 0) {
                coin::join(&mut dex_coin, coin::from_balance(balance::increase_supply(&mut self.dex_supply, FLOAT_SCALING), ctx));
            };
        } else {
            table::add(&mut self.swaps, sender, 1);
        };
        let balance_manager = get_balance_manager_mut(self);

        // Deposit coins to balance manager
        if (coin::value(&base_coin) > 0) {
            bm::deposit<ETH>(balance_manager, base_coin, ctx);
        } else {
            coin::destroy_zero(base_coin);
        };

        if (coin::value(&quote_coin) > 0) {
            bm::deposit<USDC>(balance_manager, quote_coin, ctx);
        } else {
            coin::destroy_zero(quote_coin);
        };

        // Create a trade proof (for potential future use)
        let _trade_proof = bm::generate_proof_as_owner(balance_manager, ctx);

        // For now, we'll simulate the market order since the actual API is complex
        // In a real implementation, you would need to call the actual DeepBook V3 functions
        // with all the required parameters
        
        // Simplified order execution - calculate filled amounts
        let eth_filled = if (is_bid) quantity / 100 else quantity;
        let usdc_filled = if (is_bid) quantity else quantity * 100;

        // Withdraw filled amounts
        let eth_coin = if (eth_filled > 0) {
            bm::withdraw<ETH>(balance_manager, eth_filled, ctx)
        } else {
            coin::zero(ctx)
        };

        let usdc_coin = if (usdc_filled > 0) {
            bm::withdraw<USDC>(balance_manager, usdc_filled, ctx)
        } else {
            coin::zero(ctx)
        };

        (eth_coin, usdc_coin, dex_coin)
    }

    // V3 Entry function for market orders
    public fun entry_place_market_order_v3(
        self: &mut Storage,
        pool: &mut Pool<ETH, USDC>,
        quantity: u64,
        is_bid: bool,
        base_coin: Coin<ETH>,
        quote_coin: Coin<USDC>,
        clock: &Clock,
        ctx: &mut TxContext,   
    ) {
        let (eth, usdc, coin_dex) = place_market_order_v3(self, pool, quantity, is_bid, base_coin, quote_coin, clock, ctx);
        let sender = tx_context::sender(ctx);

        transfer_coin(eth, sender);
        transfer_coin(usdc, sender);
        transfer_coin(coin_dex, sender);
    }

    // Simplified limit order function
    public fun place_limit_order_info_v3(
        self: &mut Storage,
        _pool: &mut Pool<ETH, USDC>,
        _price: u64,
        _quantity: u64,
        _is_bid: bool,
        _expire_timestamp: u64,
        _restriction: u8,
        base_coin: Coin<ETH>,
        quote_coin: Coin<USDC>,
        _clock: &Clock,
        ctx: &mut TxContext,
    ): u64 {
        self.client_id = self.client_id + 1;
        let current_client_id = self.client_id;

        let balance_manager = get_balance_manager_mut(self);

        // Deposit coins
        if (coin::value(&base_coin) > 0) {
            bm::deposit<ETH>(balance_manager, base_coin, ctx);
        } else {
            coin::destroy_zero(base_coin);
        };

        if (coin::value(&quote_coin) > 0) {
            bm::deposit<USDC>(balance_manager, quote_coin, ctx);
        } else {
            coin::destroy_zero(quote_coin);
        };

        // Return a dummy order ID since we can't actually place the order
        current_client_id
    }

    // Simplified cancel order function
    public fun cancel_order_info_v3(
        self: &mut Storage,
        _pool: &mut Pool<ETH, USDC>,
        _order_id: u128,
        _clock: &Clock,
        ctx: &mut TxContext,
    ): (Coin<ETH>, Coin<USDC>) {
        let _balance_manager = get_balance_manager_mut(self);
        let _trade_proof = bm::generate_proof_as_owner(_balance_manager, ctx);
        
        // For demonstration, return zero coins
        let eth_coin = coin::zero(ctx);
        let usdc_coin = coin::zero(ctx);

        (eth_coin, usdc_coin)
    }

    // Keep existing functions for backward compatibility
    public fun user_last_mint_epoch<CoinType>(self: &Storage, user: address): u64 {
        let data = df::borrow<TypeName, Data<CoinType>>(&self.id, type_name::get<CoinType>());
        if (table::contains(&data.faucet_lock, user)) return *table::borrow(&data.faucet_lock, user);
        0 
    }

    public fun user_swap_count(self: &Storage, user: address): u64 {
        if (table::contains(&self.swaps, user)) return *table::borrow(&self.swaps, user);
        0
    }

    public fun create_state(
        self: &mut Storage, 
        eth_cap: TreasuryCap<ETH>, 
        usdc_cap: TreasuryCap<USDC>, 
        ctx: &mut TxContext
    ) {
        df::add(&mut self.id, type_name::get<ETH>(), Data { cap: eth_cap, faucet_lock: table::new(ctx) });
        df::add(&mut self.id, type_name::get<USDC>(), Data { cap: usdc_cap, faucet_lock: table::new(ctx) });
    }

    public fun mint_coin<CoinType>(self: &mut Storage, ctx: &mut TxContext): Coin<CoinType> {
        let sender = tx_context::sender(ctx);
        let current_epoch = tx_context::epoch(ctx);
        let coin_type = type_name::get<CoinType>();
        let data = df::borrow_mut<TypeName, Data<CoinType>>(&mut self.id, coin_type);

        if (table::contains(&data.faucet_lock, sender)){
            let last_mint_epoch = table::borrow(&data.faucet_lock, tx_context::sender(ctx));
            assert!(current_epoch > *last_mint_epoch, EAlreadyMintedThisEpoch);
        } else {
            table::add(&mut data.faucet_lock, sender, 0);
        };

        let last_mint_epoch = table::borrow_mut(&mut data.faucet_lock, sender);
        *last_mint_epoch = tx_context::epoch(ctx);
        
        coin::mint(&mut data.cap, if (coin_type == type_name::get<USDC>()) 100 * FLOAT_SCALING else 1 * FLOAT_SCALING, ctx)
    }

    public fun entry_mint_coin<CoinType>(self: &mut Storage, ctx: &mut TxContext) {
        let coin = mint_coin<CoinType>(self, ctx);
        let sender = tx_context::sender(ctx);
        transfer_coin(coin, sender);
    }

    fun transfer_coin<CoinType>(c: Coin<CoinType>, sender: address) {
        if (coin::value(&c) == 0) {
            coin::destroy_zero(c);
        } else {
            transfer::public_transfer(c, sender);
        };
    }

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(DEX {}, ctx);
    }
}