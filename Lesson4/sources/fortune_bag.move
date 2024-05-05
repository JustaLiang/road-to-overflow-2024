/// Module: lesson4
module lesson4::fortune_bag {

    // Dependencies

    use std::string::utf8;
    use sui::package;
    use sui::display;
    use sui::coin::{Self, Coin};
    use sui::balance::Balance;
    use lesson4::fortune::FORTUNE;

    // Errors

    const EEmptyFund: u64 = 0;

    // Constants

    const NOT_FULL: u8 = 0;
    const FULL: u8 = 1;
    const THRESHOLD: u64 = 100_000_000_000;

    // One Time Witness

    public struct FORTUNE_BAG has drop {}

    // Object (NFT)

    public struct FortuneBag has key, store {
        id: UID,
        state: u8,
        content: Balance<FORTUNE>,
    }

    //  Constructor

    fun init(otw: FORTUNE_BAG, ctx: &mut TxContext) {
        let keys = vector[
            utf8(b"name"),
            utf8(b"description"),
            utf8(b"image_url"),
            utf8(b"project_url"),
            utf8(b"creator"),
        ];

        let values = vector[
            // name
            utf8(b"Fortune Bag"),
            // description
            utf8(b"A bag to collect FORTUNE!"),
            // image_url
            utf8(b"https://aqua-natural-grasshopper-705.mypinata.cloud/ipfs/QmYvx5XTQ4KgFbskbKbQDRWZ1pq371pHex8QFHwQaU6dJw/{state}"),
            // project_url
            utf8(b"https://app.bucketprotocol.io/"),
            // creator
            utf8(b"Justa"),
        ];

        let deployer = ctx.sender();
        let publisher = package::claim(otw, ctx);
        let mut displayer = display::new_with_fields<FortuneBag>(
            &publisher, keys, values, ctx,
        );
        display::update_version(&mut displayer);

        transfer::public_transfer(displayer, deployer);
        transfer::public_transfer(publisher, deployer);
    }

    //  Public funs

    public fun mint(
        fund: Coin<FORTUNE>,
        ctx: &mut TxContext,
    ): FortuneBag {
        assert!(fund.value() > 0, EEmptyFund);
        let state = if (fund.value() < THRESHOLD) {
            NOT_FULL
        } else {
            FULL
        };
        FortuneBag {
            id: object::new(ctx),
            state,
            content: fund.into_balance(),
        }
    }

    public fun put(
        bag: &mut FortuneBag,
        fund: Coin<FORTUNE>,
    ) {
        coin::put(&mut bag.content, fund);
        if (bag.content.value() >= THRESHOLD) {
            bag.state = FULL;
        };
    }

    public fun take(
        bag: &mut FortuneBag,
        value: u64,
        ctx: &mut TxContext,
    ): Coin<FORTUNE> {
        let coin = coin::take(&mut bag.content, value, ctx);
        if (bag.content.value() < THRESHOLD) {
            bag.state = NOT_FULL;
        };
        coin
    }

    // entry funs

    entry fun mint_to(
        fund: Coin<FORTUNE>,
        recipient: address,
        ctx: &mut TxContext,
    ) {
        let bag = mint(fund, ctx);
        transfer::transfer(bag, recipient);
    }

    entry fun take_to(
        bag: &mut FortuneBag,
        value: u64,
        recipient: address,
        ctx: &mut TxContext,
    ) {
        let coin = bag.take(value, ctx);
        transfer::public_transfer(coin, recipient);
    }

    //  Getter Funs

    public fun is_full(bag: &FortuneBag): bool {
        bag.state == FULL
    }

    public fun fortune_value(bag: &FortuneBag): u64 {
        bag.content.value()
    }

    //  Test-only funs

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        use sui::test_utils;
        init(test_utils::create_one_time_witness<FORTUNE_BAG>(), ctx);
    }
}

