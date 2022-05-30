library oracle_lib;

pub enum TypeEnum {
    Unanswered: (),
    Number: (),
    String: (),
    Hash: (),
}

// Event triggered when the nodes have arrived to a result
pub struct UpdatedRequest {
    id: u64,
    api_url: b256,
    key: b256,
    value_type: TypeEnum,
    value: b256,
}

abi Oracle {
    fn create_request(api_url: b256, key: b256, value_type: TypeEnum);
    fn update_request(id: u64, value_retrieved: b256);
    fn get_answer(id: u64) -> UpdatedRequest;
}