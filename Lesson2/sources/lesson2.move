/// Module: lesson2
module lesson2::c2c {

    // Dependencies

    use sui::coin::Coin;
    use sui::event;

    // Errors

    const EAmountNotEnough: u64 = 0;
    const EProvidedCoinNotFound: u64 = 1;
    const ENotEmpty: u64 = 2;
    const ENoAuthToCancel: u64 = 3;

    // Objects

    public struct EscrowObj<phantom P, phantom R> has key, store {
        id: UID,
        creator: address,
        provided: Option<Coin<P>>,
        requested_amount: u64,
    }

    // Events

    public struct Created<phantom P, phantom R> has copy, drop {
        id: ID,
        creator: address,
        provided_amount: u64,
        requested_amount: u64,
    }

    public struct Settled<phantom P, phantom R> has copy, drop {
        id: ID,
        creator: address,
        creator_received_amount: u64,
        settler: address,
        settler_received_amount: u64,
    }

    public struct Cancelled<phantom P, phantom R> has copy, drop {
        id: ID,
        creator: address,
        received_amount: u64,
    }

    public struct Destroyed<phantom P, phantom R> has copy, drop {
        id: ID,
    }

    // Public funs

    public fun create<P, R>(
        coin: Coin<P>,
        requested_amount: u64,
        ctx: &mut TxContext,
    ) {
        let provided_amount = coin.value();
        let creator = ctx.sender();
        let obj = EscrowObj<P, R> {
            id: object::new(ctx),
            creator,
            provided: option::some(coin),
            requested_amount,
        };
        let object_id = object::id(&obj);
        event::emit(Created<P, R> {
            id: object_id,
            creator,
            provided_amount,
            requested_amount,
        });
        transfer::share_object(obj);
    }

    public fun settle<P, R>(
        escrow_obj: &mut EscrowObj<P, R>,
        requested_coin: Coin<R>,
        ctx: &TxContext,
    ): Coin<P> {
        let requested_coin_value = requested_coin.value();
        if (requested_coin_value < escrow_obj.requested_amount) {
            abort EAmountNotEnough
        };

        let creator = escrow_obj.creator;
        transfer::public_transfer(requested_coin, creator);

        if (escrow_obj.provided.is_none()) {
            abort EProvidedCoinNotFound
        };
        let escrowed_coin = escrow_obj.provided.extract();
        event::emit(Settled<P, R> {
            id: object::id(escrow_obj),
            creator: escrow_obj.creator,
            creator_received_amount: requested_coin_value,
            settler: ctx.sender(),
            settler_received_amount: escrowed_coin.value(),
        });
        escrowed_coin
        // transfer::public_transfer(escrowed_coin, tx_sender);
    }

    public fun cancel<P, R>(
        escrow_obj: &mut EscrowObj<P, R>,
        ctx: &TxContext,
    ): Coin<P> {
        if (escrow_obj.creator != ctx.sender()) {
            abort ENoAuthToCancel
        };
        let escrowed_coin = escrow_obj.provided.extract();
        event::emit(Cancelled<P, R> {
            id: object::id(escrow_obj),
            creator: escrow_obj.creator,
            received_amount: escrowed_coin.value(),
        });
        escrowed_coin
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

        event::emit(Destroyed<P, R> {
            id: id.to_inner(),
        });
        object::delete(id);
        provided.destroy_none();
    }

    // Getter funs

    public fun creator<P, R>(obj: &EscrowObj<P, R>): address {
        obj.creator
    }

    public fun provided_value<P, R>(obj: &EscrowObj<P, R>): Option<u64> {
        if (obj.provided.is_some()) {
            let coin_ref = obj.provided.borrow();
            option::some(coin_ref.value())
        } else {
            option::none()
        }
    }

    public fun requested_amount<P, R>(obj: &EscrowObj<P, R>): u64 {
        obj.requested_amount
    }
}
