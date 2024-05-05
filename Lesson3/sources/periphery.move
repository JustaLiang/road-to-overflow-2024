/// Module: lesson3
module lesson3::c2c_periphery {    

    // Dependencies

    use sui::coin::Coin;
    use lesson2::c2c::{Self, EscrowObj};

    // Entry funs

    entry fun settle<P, R>(
        escrow_obj: &mut EscrowObj<P, R>,
        requested_coin: Coin<R>,
        recipient: address,
        ctx: &TxContext,
    ) {
        let coin = c2c::settle(escrow_obj, requested_coin, ctx);
        transfer::public_transfer(coin, recipient);
    }

    entry fun cancel<P, R>(
        escrow_obj: &mut EscrowObj<P, R>,
        recipient: address,
        ctx: &TxContext,
    ) {
        let coin = c2c::cancel(escrow_obj, ctx);
        transfer::public_transfer(coin, recipient);
    }
}
