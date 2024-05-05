/// Module: fortune
module lesson4::fortune {

    // Dependencies

    use sui::coin::{Self, Coin, TreasuryCap};
    use sui::balance::{Self, Balance};
    use sui::url;

    // One Time Witness

    public struct FORTUNE has drop {}

    // Objects

    public struct Treasury has key {
        id: UID,
        cap: TreasuryCap<FORTUNE>,
    }

    public struct AdminCap has key, store {
        id: UID,
    }

    // Constructor

    fun init(otw: FORTUNE, ctx: &mut TxContext) {
        // create fungible token
        let url = url::new_unsafe_from_bytes(
            b"https://aqua-natural-grasshopper-705.mypinata.cloud/ipfs/Qmeyz3FijdgyR9AMqg84nzpQR4sXbZd1M4UBhQ9Dz99sYE"
        );
        let (cap, metadata) = coin::create_currency(
            otw,
            9,
            b"FTN",
            b"Fortune Coin",
            b"Collect Fortune to get special NFT",
            option::some(url),
            ctx,
        );

        // make metadata immutable
        transfer::public_freeze_object(metadata);

        // wrap TreasuryCap in Treasury and share
        let treasury = Treasury {
            id: object::new(ctx),
            cap,
        };
        transfer::share_object(treasury);

        // give AdminCap to deployer
        let admin_cap = AdminCap { id: object::new(ctx) };
        transfer::transfer(admin_cap, ctx.sender());
    }

    // Public funs

    public fun mint(
        treasury: &mut Treasury,
        _: &AdminCap,
        value: u64,
        ctx: &mut TxContext,
    ): Coin<FORTUNE> {
        coin::mint(&mut treasury.cap, value, ctx)
    }

    public struct FlashMintRecipit {
        value: u64,
    }

    public fun flash_mint(
        treasury: &mut Treasury,
        value: u64,
        ctx: &mut TxContext,
    ): (Coin<FORTUNE>, FlashMintRecipit) {
        let coin = coin::mint(&mut treasury.cap, value, ctx);
        let recipit = FlashMintRecipit { value };
        (coin, recipit)
    }

    public fun flash_burn(
        treasury: &mut Treasury,
        coin: Coin<FORTUNE>,
        recipit: FlashMintRecipit,
    ) {
        let FlashMintRecipit {
            value: recipit_value,
        } = recipit;
        if (coin.value() != recipit_value) {
            abort 123
        };
        burn(treasury, coin.into_balance());
    }

    // Entry funs

    entry fun mint_to(
        treasury: &mut Treasury,
        cap: &AdminCap,
        value: u64,
        recipient: address,
        ctx: &mut TxContext,
    ) {
        let coin = mint(treasury, cap, value, ctx);
        transfer::public_transfer(coin, recipient);
    }

    // Package funs

    public(package) fun burn(
        treasury: &mut Treasury,
        balance: Balance<FORTUNE>,
    ) {
        balance::decrease_supply(treasury.cap.supply_mut(), balance);
    }

    //  Test-only funs

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        use sui::test_utils;
        init(test_utils::create_one_time_witness<FORTUNE>(), ctx);
    }

}