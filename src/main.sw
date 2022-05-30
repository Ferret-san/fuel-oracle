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
    InvalidOracle: (),
}

// Defines an API request
pub struct Request {
    id: u64,
    api_url: b256,
    key: b256,
    value_type: TypeEnum,
}

storage {
    request_id: u64 = 0,
}

const REQUEST_DOMAIN_SEPARATOR: b256 = 0x0000000000000000000000000000000000000000000000000000000000000001;
const VOTED_DOMAIN_SEPARATOR: b256 = 0x0000000000000000000000000000000000000000000000000000000000000002;
const ANSWER_DOMAIN_SEPARATOR: b256 = 0x0000000000000000000000000000000000000000000000000000000000000003;

impl Oracle for Contract {
    fn create_request(api_url: b256, key: b256, value_type: TypeEnum) {
        // Assemble the request
        let request = Request {
            id: storage.request_id,
            api_url: api_url,
            key: key,
            value_type: value_type,
        };

        // Store the request
        let request_storage_slot = sha256((REQUEST_DOMAIN_SEPARATOR, storage.request_id));
        store(request_storage_slot, request);

        // Store requestTypeEnum
        storage.request_id = storage.request_id + 1;
    }

    fn update_request(id: u64, value_retrieved: b256) {
        let sender: Result<Sender, AuthError> = msg_sender();
        let sender = if let Sender::Address(addr) = sender.unwrap() {
            addr.value
        } else {
            revert(0);
        };

        // check the message sender is one of the three oracles
        let is_one_of_signers = match sender {
            0x6b63804cfbf9856e68e5b6e7aef238dc8311ec55bec04df774003a2c96e0418e => true, 0x54944e5b8189827e470e5a8bacfc6c3667397dc4e1eef7ef3519d16d6d6c6610 => true, 0xe10f526b192593793b7a1559a391445faba82a1d669e3eb2dcd17f9c121b24b1 => true, _ => false, 
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

            // list of hard coded oracles to go through
            let oracles = [0x6b63804cfbf9856e68e5b6e7aef238dc8311ec55bec04df774003a2c96e0418e, 0x54944e5b8189827e470e5a8bacfc6c3667397dc4e1eef7ef3519d16d6d6c6610, 0xe10f526b192593793b7a1559a391445faba82a1d669e3eb2dcd17f9c121b24b1];

            // check if quorum has been reched
            let mut current_consensus = 0;
            let mut counter = 0;
            while counter < 3 {
                let oracle_answer_storage_slot = sha256((ANSWER_DOMAIN_SEPARATOR, sha256((id, oracles[counter]))));
                let answer = get::<b256>(oracle_answer_storage_slot);

                if answer == value_retrieved {
                    current_consensus = current_consensus + 1;
                    if (current_consensus >= 2) {
                        // get request for the given id
                        let storage_slot = sha256((REQUEST_DOMAIN_SEPARATOR, id));
                        let request = get::<Request>(storage_slot);
                        log(UpdatedRequest {
                            id: request.id, api_url: request.api_url, key: request.key, value_type: request.value_type, value: value_retrieved, 
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
