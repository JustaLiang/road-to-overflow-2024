/// Module: justatest
module lesson1::lesson1 {

    use std::string::String;

    public fun hello_world(): String {
        b"hello world".to_string()
    }

    public fun sum(a: u64, b: u64): u64 {
        a + b
    }

    public fun try_borrow(vec: &vector<u64>, i: u64): Option<u64> {
        let vec_len = vec.length();
        if (vec_len > i) {
            option::some(*vec.borrow(i))
        } else {
            option::none()
        }
    }

    #[test_only]
    public fun numbers(): vector<u64> { vector[1, 2, 3] }
}

