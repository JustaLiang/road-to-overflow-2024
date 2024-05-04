#[test_only]
module lesson2::lesson2_tests {

    use sui::test_scenario as ts;
    use sui::sui::SUI;
    use sui::coin::{Self, Coin};
    use lesson2::c2c::{Self, EscrowObj};
    use lesson2::buck::BUCK;

    #[test]
    fun test_positive() {
        let user1 = @0xc0ffee;
        let user2 = @0x123456;
        let sui_amount = 100_000_000_000;
        let buck_amount = 109_000_000_000;
        let mut scenario_val = ts::begin(user1);
        let s = &mut scenario_val;
        {
            let sui_coin = coin::mint_for_testing<SUI>(sui_amount, ts::ctx(s));
            c2c::create<SUI, BUCK>(
                sui_coin,
                buck_amount,
                ts::ctx(s),
            );
        };

        ts::next_tx(s, user2);
        {
            let mut escrowed_obj = ts::take_shared<EscrowObj<SUI, BUCK>>(s);

            let buck_coin = coin::mint_for_testing<BUCK>(buck_amount, ts::ctx(s));
            let sui_coin = c2c::settle(
                &mut escrowed_obj,
                buck_coin,
            );
            transfer::public_transfer(sui_coin, user2);

            ts::return_shared(escrowed_obj);
        };

        ts::next_tx(s, user1);
        {
            let buck_coin = ts::take_from_sender<Coin<BUCK>>(s);
            assert!(buck_coin.value() == buck_amount, 0);
            ts::return_to_sender(s, buck_coin);
        };

        ts::next_tx(s, user2);
        {
            let sui_coin = ts::take_from_sender<Coin<SUI>>(s);
            assert!(sui_coin.value() == sui_amount, 0);
            ts::return_to_sender(s, sui_coin);
        };

        ts::end(scenario_val);
    }

    #[test, expected_failure(abort_code = c2c::EAmountNotEnough)]
    fun test_not_enough() {
        let user1 = @0xc0ffee;
        let user2 = @0x123456;
        let sui_amount = 100_000_000_000;
        let buck_amount = 109_000_000_000;
        let mut scenario_val = ts::begin(user1);
        let s = &mut scenario_val;
        {
            let sui_coin = coin::mint_for_testing<SUI>(sui_amount, ts::ctx(s));
            c2c::create<SUI, BUCK>(
                sui_coin,
                buck_amount,
                ts::ctx(s),
            );
        };

        ts::next_tx(s, user2);
        {
            let mut escrowed_obj = ts::take_shared<EscrowObj<SUI, BUCK>>(s);

            let buck_coin = coin::mint_for_testing<BUCK>(
                buck_amount - 1, ts::ctx(s),
            );
            let sui_coin = c2c::settle(
                &mut escrowed_obj,
                buck_coin,
            );
            transfer::public_transfer(sui_coin, user2);

            ts::return_shared(escrowed_obj);
        };

        ts::end(scenario_val);
    }
}

module lesson2::buck {
    public struct BUCK has drop {}
}
