library oracle_lib;

use std::{address::Address};

pub enum TypeEnum {
    Unanswered: (),
    Number: (),
    String: (),
    Hash: (),
}

// Event triggered when the nodes have arrived to a result
pub struct UpdatedRequest {
    id: u64,
    api_url: str[76],
    key: str[12],
    value: u64,
}

abi Oracle {
    fn initialize(oracle_1: Address, oracle_2: Address, oracle_3: Address);
    fn create_request();
    fn update_request(id: u64, value_retrieved: u64);
    fn get_answer(id: u64) -> UpdatedRequest;
}
