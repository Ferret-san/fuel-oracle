use fuels::{prelude::*, tx::ContractId};
use fuels_abigen_macro::abigen;

// Load abi from json
abigen!(Oracle, "out/debug/fuel-oracle-abi.json");

async fn get_oracle_instance() -> (Oracle, ContractId) {
    // Launch a local network and deploy the contract
    let wallet = launch_provider_and_get_single_wallet().await;

    let id = Contract::deploy(
        "./out/debug/fuel-oracle.bin",
        &wallet,
        TxParameters::default(),
    )
    .await
    .unwrap();

    let instance = Oracle::new(id.to_string(), wallet);

    (instance, id)
}

#[tokio::test]
async fn can_get_contract_id() {
    let (_oracle, _id) = get_oracle_instance().await;

    let value_type = oracle_mod::TypeEnum::Number();
    let api_url = "https://api.coingecko.com/api/v3/simple/price?ids=ethereum&vs_currencies=usd";
    let api_url = api_url.as_bytes();
    let key = "ethereum.usd";
    let key = key.as_bytes();
    //
    _oracle.create_request(api_url, key, value_type);
}
