use coingecko::CoinGeckoClient;
use fuels::signers::wallet::Wallet;
use fuels::{prelude::*, tx::ContractId};
use fuels_abigen_macro::abigen;

// Load abi from json
abigen!(Oracle, "out/debug/fuel-oracle-abi.json");

async fn get_oracle_instance() -> (Oracle, ContractId, Wallet, Wallet, Wallet) {
    let num_wallets = 4;
    let coins_per_wallet = 1;
    let amount_per_coin = 1_000_000;

    let config = WalletsConfig::new(
        Some(num_wallets),
        Some(coins_per_wallet),
        Some(amount_per_coin),
    );
    // Launch a local network and deploy the contract
    let mut wallets = launch_provider_and_get_wallets(config).await;

    let deployer_wallet = wallets.pop().unwrap();

    println!("Deployer: {:?}", deployer_wallet);

    let id = Contract::deploy(
        "./out/debug/fuel-oracle.bin",
        &deployer_wallet,
        TxParameters::default(),
    )
    .await
    .unwrap();

    let instance = Oracle::new(id.to_string(), deployer_wallet);

    let oracle_1 = wallets.pop().unwrap();
    println!("Oracle 1: {:?}", oracle_1.address());

    let oracle_2 = wallets.pop().unwrap();
    println!("Oracle 2: {:?}", oracle_2.address());

    let oracle_3 = wallets.pop().unwrap();
    println!("Oracle 3: {:?}", oracle_2.address());

    (instance, id, oracle_1, oracle_2, oracle_3)
}

#[tokio::test]
async fn call_oracle() {
    let (_oracle, _id, oracle_1, oracle_2, oracle_3) = get_oracle_instance().await;

    let _initialize_quorum = _oracle
        .initialize(oracle_1.address(), oracle_2.address(), oracle_3.address())
        .call()
        .await
        .unwrap();

    let _create_request = _oracle.create_request().call().await.unwrap();

    // SKIP API REQUEST FOR NOW, RAN OUT OF TIME TO TEST
    // let client = CoinGeckoClient::default();
    // let result = client
    //     .price(&["ethereum"], &["usd"], true, true, true, true)
    //     .await;
    // println!("Result: {:?}", result);

    // Make instance for each oracle
    let oracle_1_instance = Oracle::new(_id.to_string(), oracle_1);
    let oracle_2_instance = Oracle::new(_id.to_string(), oracle_2);
    let oracle_3_instance = Oracle::new(_id.to_string(), oracle_3);

    let _oracle_1_fulfill = oracle_1_instance.update_request(0, 1800).call().await;
    let _oracle_2_fulfill = oracle_2_instance.update_request(0, 1800).call().await;
    let _oracle_3_fulfill = oracle_3_instance.update_request(0, 1800).call().await;

    let _get_answer = _oracle.get_answer(0).call().await.unwrap();
    println!("Answer: {:?}", _get_answer);
}
