# Sway based Oracle for the FuelVM

## Overview

The purpose of this repository is to show the implementation of a simple 2/3 Oracle system for Fuel written in Sway. 
By no means is it robust and should not be used in production, since it is instead meant to be used as an example.

## Repository Structure

The following is a visual sample of how the repository is structured.

```
fuel-oracle/
├── oracle_lib
|    └── ABI and structs for the Oracle contract
├── src
|    └── Oracle implementation
├── tests
|    └── Oracle implementation testing
└── README.md
```

## Running the project

To test the implementation, simply run `forc test -- --nocapture`

## What the project is meant to achieve

I set out to build a full end-end 2/3 oracle implementation, in which anyone could file a request for a given url 
and key for the json value they wanted to retrieve, which would fire an event oracles would be looking for, and once 
the oracles saw the event, they would take the data from the event (url and key), call some API, get the result,
and then each would fulfill the request. Once quorum is reached, a value for the request can be retrieved.

## What was achieved

An implementation for a 2/3 Oracle in sway, with minimal testing to show that the general flow described above works.
However, there is no offchain-node implementation, the api url is hardcoded for the sake of simplicity, and I ran out
of time to make the api request, parse the json, and fulfill the request, so the return in the test by the oracles
is hardcoded.

## Limitations

Some limitation I encountered while working on this:
- Can't pass strings as a parameter
- Can't declare generic functions in an ABI declaration 
- No "off-chain" oracle code due to:
  - Typechain wasn't working for me
  - Rust SDK has no `get_blocks()` method at the time of writting this (05/30/2022)
  - I was told in Discord that the client connections through the SDK are one time only, and so I couldn't set up a listener.
  - No abi encoding/decoding, so I didn't have time to decode the logs for the transactions.
  - Tired and lacked time lol
- I had to harcode the API endpoint to simplify things, so this Oracle only returns the price of ETH in USD
- The oracles have to reach an agreement (i.e 2 responses must be equal), thus any price deviation will cause the oracles to not reach quorum

## What I would like to improve upon

- Complete the "off-chain" portion of the Oracle
- Add support for different types and different API endpoints
- Explore other oracle implementations (2/3 is not exactly ideal, so there are other implementations out there that could be built for the FuelVM)
