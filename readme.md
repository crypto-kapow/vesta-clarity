# Getting Started
## Installation
Make sure clarinet is installed

## Running Contracts (Basics)
The Clarinet is good for quick tests of contarcts -BUT not accurate for mining-. The burnchain blocks in the local dev environment are not consistent and the history is inaccurate. Running a query for who won a block will be inconsistent even within the same session.

Start the console by running:
`clarinet console`
This can be run in a separate command prompt or within the Terminal in VS Code.

This will show all contracts deployed to the local development environment
10 test addresses will also be created
The 1st address is where the contracts are deployed and is set as the caller for function calls made
To switch the caller, run
`::set_tx_sender STNHKEPYEPJ8ET55ZZ0M5A34J0R3N5FM2CMMMAZ6`

You -must- restart the console to reload any changes to the code.

3/30/25 - These instructions will likely get outdated sooner than later..

## Listing Assets (Clarinet Console)
Run 
`::get_assets_maps`
Should see:
* The first address (GZGM) has less STX
* a new .mining address has the correct portion of STX from the total commit
* a new .pool address has the correct portion of STX from the total commit

## Running Contracts (Examples)
At the console, run the following command:
`(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.miner pox-mine u0 (list u10000000 u10000000 u2000000) )`
That will call the miner contract and run the pox-mine function with the following parameters:
* u0 - the starting block height - 0 (or the first) coin block height.
* List of STX to commit to the starting and subsequent blocks. Checks are made in the contract that only whole STX are committed.

On success, should get something like:
`(ok { conductor: u440000, event: "Mining Commit Complete", miners: u19800000, pool: u1760000 })`

Run
`(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.blockchain get-mining-start-block)`
Response: u170
Indicates the first BTC height for our blocks genesis (block 0) block


Run
`(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.blockchain next-mining-block)`
Response: (ok { burnBlock: u170, height: u0 })

Run
::advance_burn_chain_tip xxx
Response: Will show current STX and BTC height. We only care about the BTC height.

Get the height to 170

`(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.blockchain next-mining-block)`
Response: (ok { burnBlock: u176, height: u1 })
The coin block has properly advanced

## Testnet - Allowing calls from a browser
These steps run a full testnet on your local system. This is a full BTC node and a full STX node to test with.

* Start Docker
* From the Clarinet directory, run
`clarinet devnet start`

The interface should show up. It usually takes until BTC block 25-30 for the contracts to be deployed and usable. Once deployed, contract calls from stacks-js (through the website) or tx-interface can be made.

