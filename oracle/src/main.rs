use fuel_core::service::{Config, FuelService};
use fuel_gql_client::client::FuelClient;
use fuels::prelude::{
    launch_provider_and_get_single_wallet, setup_multiple_assets_coins, setup_single_asset_coins,
    setup_test_provider, CallParameters, Contract, Error, LocalWallet, Provider, Signer,
    TxParameters, DEFAULT_COIN_AMOUNT, DEFAULT_NUM_COINS,
};

#[tokio::main]
async fn main() {
    let server = FuelService::new_node(Config::local_node()).await.unwrap();
    let client = FuelClient::from(server.bound_address);

    
    println!("Client launched!");
}
