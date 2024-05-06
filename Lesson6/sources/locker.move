/// Module: lesson6
module lesson6::locker {

    // Dependencies

    use sui::dynamic_field as df;

    // Objects

    public struct Locker has key {
        id: UID,
    }

    public struct Key<phantom T> has key, store {
        id: UID,
    }

    // Public funs

    public fun create(ctx: &mut TxContext) {
        transfer::share_object(
            Locker { id: object::new(ctx) }
        );
    }

    public fun lock<T: store>(
        locker: &mut Locker,
        obj: T,
        ctx: &mut TxContext,
    ): Key<T> {
        let key = Key { id: object::new(ctx) };
        let key_id = object::id(&key);
        df::add(&mut locker.id, key_id, obj);
        key
    }

    public fun unlock<T: store>(
        locker: &mut Locker,
        key: Key<T>,
    ): T {
        let key_id = object::id(&key);
        let Key { id } = key;
        id.delete();
        df::remove<ID, T>(&mut locker.id, key_id)
    }

    public fun borrow<T: store>(
        locker: &Locker,
        key: &Key<T>,
    ): &T {
        let key_id = object::id(key);
        df::borrow<ID, T>(&locker.id, key_id)
    }

    public fun borrow_mut<T: store>(
        locker: &mut Locker,
        key: &Key<T>,
    ): &mut T {
        let key_id = object::id(key);
        df::borrow_mut<ID, T>(&mut locker.id, key_id)
    }
}
