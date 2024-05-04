/// Module: lesson2
module lesson2::c2c {

    use sui::coin::Coin;
    use sui::event;

    const EAmountNotEnough: u64 = 0;
    const EProvidedCoinNotFound: u64 = 1;
    const ENotEmpty: u64 = 2;

    public struct EscrowObj<phantom P, phantom R> has key, store {
        id: UID,
        creator: address,
        provided: Option<Coin<P>>,
        requested_amount: u64,
    }

    public struct EscrowCreated<phantom P, phantom R> has copy, drop {
        id: ID,
        provided_amount: u64,
        requested_amount: u64,
    }

    // TODO: EscrowSettled

    public fun create<P, R>(
        coin: Coin<P>,
        requested_amount: u64,
        ctx: &mut TxContext,
    ) {
        let provided_amount = coin.value();
        let obj = EscrowObj<P, R> {
            id: object::new(ctx),
            creator: ctx.sender(),
            provided: option::some(coin),
            requested_amount,
        };
        let object_id = object::id(&obj);
        event::emit(EscrowCreated<P, R> {
            id: object_id,
            provided_amount,
            requested_amount,
        });
        transfer::share_object(obj);
    }

    public fun settle<P, R>(
        escrow_obj: &mut EscrowObj<P, R>,
        requested_coin: Coin<R>,
    ): Coin<P> {
        let coin_value = requested_coin.value();
        if (coin_value < escrow_obj.requested_amount) {
            abort EAmountNotEnough
        };

        let creator = escrow_obj.creator;
        transfer::public_transfer(requested_coin, creator);

        if (escrow_obj.provided.is_none()) {
            abort EProvidedCoinNotFound
        };
        let escrowed_coin = escrow_obj.provided.extract();
        escrowed_coin
        // transfer::public_transfer(escrowed_coin, tx_sender);
    }

    public fun destroy_empty<P, R>(
        obj: EscrowObj<P, R>,
    ) {
        if (obj.provided.is_some()) {
            abort ENotEmpty
        };
        let EscrowObj {
            id,
            creator: _,
            provided,
            requested_amount: _,
        } = obj;

        object::delete(id);
        provided.destroy_none();
    }

    // TODO: take_back
}
