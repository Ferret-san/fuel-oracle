contract;

use std::{
    address::Address,
    assert::require,
    chain::auth::{AuthError, Sender, msg_sender},
    hash::sha256,
    logging::log,
    result::*,
    revert::revert,
    storage::{get, store}
};

use oracle_lib::*;

const TOTAL_ORACLE_COUNT = 3;

pub enum Errors {
    NotInitialized: (),
    AlreadyInitialized: (),
    InvalidOracle: (),
}

// Defines an API request
pub struct Request {
    id: u64,
    api_url: str[76],
    key: str[12],
}

storage {
    is_initialized: bool = false,
    request_id: u64 = 0,
    oracle_1: Address,
    oracle_2: Address,
    oracle_3: Address,
}

const REQUEST_DOMAIN_SEPARATOR: b256 = 0x0000000000000000000000000000000000000000000000000000000000000001;
const VOTED_DOMAIN_SEPARATOR: b256 = 0x0000000000000000000000000000000000000000000000000000000000000002;
const ANSWER_DOMAIN_SEPARATOR: b256 = 0x0000000000000000000000000000000000000000000000000000000000000003;

impl Oracle for Contract {
    fn initialize(oracle_1: Address, oracle_2: Address, oracle_3: Address) {
        require(storage.is_initialized == false, Errors::AlreadyInitialized());
        // switch to true
        storage.is_initialized = true;
        // Assign oracles
        storage.oracle_1 = oracle_1;
        storage.oracle_2 = oracle_2;
        storage.oracle_3 = oracle_3;

        log( "Quorum initialized");
    }

    fn create_request() {
        require(storage.is_initialized == true, Errors::NotInitialized());
        // Assemble the request
        let request = Request {
            id: storage.request_id,
            api_url: "https://api.coingecko.com/api/v3/simple/price?ids=ethereum&vs_currencies=usd", key: "ethereum.usd", 
        };

        // Store the request
        let request_storage_slot = sha256((REQUEST_DOMAIN_SEPARATOR, storage.request_id));
        store(request_storage_slot, request);

        log(request);
        // Store requestTypeEnum
        storage.request_id = storage.request_id + 1;
    }

    fn update_request(id: u64, value_retrieved: u64) {
        let sender: Result<Sender, AuthError> = msg_sender();
        let sender = if let Sender::Address(addr) = sender.unwrap() {
            addr.value
        } else {
            revert(0);
        };

        let oracle_1 = storage.oracle_1;
        let oracle_2 = storage.oracle_2;
        let oracle_3 = storage.oracle_3;

        // check the message sender is one of the three oracles
        let is_one_of_signers = match sender {
            oracle_1 => true, 
            oracle_2 => true, 
            oracles_3 => true, 
            _ => false, 
        };

        // revert if the message sender is not part of the quorum
        require(is_one_of_signers == true, Errors::InvalidOracle);

        // Check if the oracle has voted on a value
        let voted_storage_slot = sha256((VOTED_DOMAIN_SEPARATOR, sha256((id, sender))));
        let has_voted = get::<bool>(voted_storage_slot);

        if has_voted == false {
            // change voting status to `true`
            store(voted_storage_slot, true);

            // publish an answer to the request
            let answer_storage_slot = sha256((ANSWER_DOMAIN_SEPARATOR, sha256((id, sender))));
            store(answer_storage_slot, value_retrieved);

            // list of oracles to go through
            let oracles = [
                oracle_1, 
                oracle_2, 
                oracle_3
            ];
            // check if quorum has been reched
            let mut current_consensus = 0;
            let mut counter = 0;
            while counter < 3 {
                let oracle_answer_storage_slot = sha256((ANSWER_DOMAIN_SEPARATOR, sha256((id, oracles[counter]))));
                let answer = get::<u64>(oracle_answer_storage_slot);

                if answer == value_retrieved {
                    current_consensus = current_consensus + 1;
                    if (current_consensus >= 2) {
                        // get request for the given id
                        let storage_slot = sha256((REQUEST_DOMAIN_SEPARATOR, id));
                        let request = get::<Request>(storage_slot);
                        log(UpdatedRequest {
                            id: request.id, api_url: request.api_url, key: request.key, value: value_retrieved, 
                        })
                    }
                }
                counter = counter + 1;
            }
        }
    }

    fn get_answer(id: u64) -> UpdatedRequest {
        let request_storage_slot = sha256((REQUEST_DOMAIN_SEPARATOR, id));
        let answer = get::<UpdatedRequest>(request_storage_slot);
        answer
    }
}
