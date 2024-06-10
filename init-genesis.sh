#!/bin/bash

BASEFOLDER=$(pwd)
echo $BASEFOLDER

# Set dedicated home directory for the evmosd instance
HOMEDIR="$BASEFOLDER/validator-folder"
HOMEDIRVALIDATOR2="$BASEFOLDER/validator2-folder"

mkdir -p $HOMEDIR
mkdir -p $HOMEDIRVALIDATOR2

CHAINID="evmos_9000-1"
MONIKER="localtestnet"
KEYRING="test"
KEYALGO="eth_secp256k1"
LOGLEVEL="info"
TRACE=""
BASEFEE=1000000000

# Path variables
CONFIG=$HOMEDIR/config/config.toml
CONFIGVALIDATOR2=$HOMEDIRVALIDATOR2/config/config.toml
APP_TOML=$HOMEDIR/config/app.toml
GENESIS=$HOMEDIR/config/genesis.json
TMP_GENESIS=$HOMEDIR/config/tmp_genesis.json

set -e
# Set client config
evmosd config keyring-backend "$KEYRING" --home "$HOMEDIR"
evmosd config chain-id "$CHAINID" --home "$HOMEDIR"

VAL_KEY="mykey"
VAL_MNEMONIC="gesture inject test cycle original hollow east ridge hen combine junk child bacon zero hope comfort vacuum milk pitch cage oppose unhappy lunar seat"

# Import keys from mnemonics
echo "$VAL_MNEMONIC" | evmosd keys add "$VAL_KEY" --recover --keyring-backend "$KEYRING" --algo "$KEYALGO" --home "$HOMEDIR"

# Store the validator address in a variable to use it later
node_address=$(evmosd keys show -a "$VAL_KEY" --keyring-backend "$KEYRING" --home "$HOMEDIR")

# Set moniker and chain-id for Evmos (Moniker can be anything, chain-id must be an integer)
evmosd init $MONIKER -o --chain-id "$CHAINID" --home "$HOMEDIR"

# Change parameter token denominations to aevmos
jq '.app_state["staking"]["params"]["bond_denom"]="aevmos"' "$GENESIS" >"$TMP_GENESIS" && mv "$TMP_GENESIS" "$GENESIS"
jq '.app_state["crisis"]["constant_fee"]["denom"]="aevmos"' "$GENESIS" >"$TMP_GENESIS" && mv "$TMP_GENESIS" "$GENESIS"
jq '.app_state["gov"]["deposit_params"]["min_deposit"][0]["denom"]="aevmos"' "$GENESIS" >"$TMP_GENESIS" && mv "$TMP_GENESIS" "$GENESIS"
# When upgrade to cosmos-sdk v0.47, use gov.params to edit the deposit params
jq '.app_state["gov"]["params"]["min_deposit"][0]["denom"]="aevmos"' "$GENESIS" >"$TMP_GENESIS" && mv "$TMP_GENESIS" "$GENESIS"
jq '.app_state["evm"]["params"]["evm_denom"]="aevmos"' "$GENESIS" >"$TMP_GENESIS" && mv "$TMP_GENESIS" "$GENESIS"
jq '.app_state["inflation"]["params"]["mint_denom"]="aevmos"' "$GENESIS" >"$TMP_GENESIS" && mv "$TMP_GENESIS" "$GENESIS"

# Set gas limit in genesis
jq '.consensus_params["block"]["max_gas"]="10000000"' "$GENESIS" >"$TMP_GENESIS" && mv "$TMP_GENESIS" "$GENESIS"


# Set base fee in genesis
jq '.app_state["feemarket"]["params"]["base_fee"]="'${BASEFEE}'"' "$GENESIS" >"$TMP_GENESIS" && mv "$TMP_GENESIS" "$GENESIS"

sed -i '' 's/timeout_propose = "3s"/timeout_propose = "30s"/g' "$CONFIG"
sed -i '' 's/timeout_propose_delta = "500ms"/timeout_propose_delta = "5s"/g' "$CONFIG"
sed -i '' 's/timeout_prevote = "1s"/timeout_prevote = "10s"/g' "$CONFIG"
sed -i '' 's/timeout_prevote_delta = "500ms"/timeout_prevote_delta = "5s"/g' "$CONFIG"
sed -i '' 's/timeout_precommit = "1s"/timeout_precommit = "10s"/g' "$CONFIG"
sed -i '' 's/timeout_precommit_delta = "500ms"/timeout_precommit_delta = "5s"/g' "$CONFIG"
sed -i '' 's/timeout_commit = "5s"/timeout_commit = "150s"/g' "$CONFIG"
sed -i '' 's/timeout_broadcast_tx_commit = "10s"/timeout_broadcast_tx_commit = "150s"/g' "$CONFIG"

# Change proposal periods to pass within a reasonable time for local testing
sed -i.bak 's/"max_deposit_period": "172800s"/"max_deposit_period": "30s"/g' "$GENESIS"
sed -i.bak 's/"voting_period": "172800s"/"voting_period": "30s"/g' "$GENESIS"

# set custom pruning settings
sed -i.bak 's/pruning = "default"/pruning = "custom"/g' "$APP_TOML"
sed -i.bak 's/pruning-keep-recent = "0"/pruning-keep-recent = "2"/g' "$APP_TOML"
sed -i.bak 's/pruning-interval = "0"/pruning-interval = "10"/g' "$APP_TOML"

# Allocate genesis accounts (cosmos formatted addresses)
evmosd add-genesis-account "$(evmosd keys show "$VAL_KEY" -a --keyring-backend "$KEYRING" --home "$HOMEDIR")" 100000000000000000000000000aevmos --keyring-backend "$KEYRING" --home "$HOMEDIR"
total_supply=100000000000000000000000000
jq -r --arg total_supply "$total_supply" '.app_state["bank"]["supply"][0]["amount"]=$total_supply' "$GENESIS" >"$TMP_GENESIS" && mv "$TMP_GENESIS" "$GENESIS"

# Sign genesis transaction
evmosd gentx "$VAL_KEY" 1000000000000000000000aevmos --gas-prices ${BASEFEE}aevmos --keyring-backend "$KEYRING" --chain-id "$CHAINID" --home "$HOMEDIR"

# Collect genesis tx
evmosd collect-gentxs --home "$HOMEDIR"

# Run this to ensure everything worked and that the genesis file is setup correctly
evmosd validate-genesis --home "$HOMEDIR"


# Set up the validator2 node
evmosd config keyring-backend "$KEYRING" --home "$HOMEDIRVALIDATOR2"
evmosd config chain-id "$CHAINID" --home "$HOMEDIRVALIDATOR2"
evmosd init RPC -o --chain-id "$CHAINID" --home "$HOMEDIRVALIDATOR2"
cp "$HOMEDIR"/config/genesis.json "$HOMEDIRVALIDATOR2"/config/genesis.json

# Change ports for the validator node to not conflict with the validator2
sed -i.bak 's/1317/11317/g' "$APP_TOML"
sed -i.bak 's/8080/18080/g' "$APP_TOML"
sed -i.bak 's/9090/19090/g' "$APP_TOML"
sed -i.bak 's/9091/19091/g' "$APP_TOML"
sed -i.bak 's/8545/18545/g' "$APP_TOML"
sed -i.bak 's/8546/18546/g' "$APP_TOML"
sed -i.bak 's/6065/16065/g' "$APP_TOML"

sed -i '' 's/26658/36658/g' "$CONFIG"
sed -i '' 's/26657/36657/g' "$CONFIG"
sed -i '' 's/6060/36060/g' "$CONFIG"
sed -i '' 's/26656/36656/g' "$CONFIG"
sed -i '' 's/26660/36660/g' "$CONFIG"

# Connect the validator2 to the validator node
NODEID=$(evmosd tendermint show-node-id --home "$HOMEDIR")
sed -i '' "s/persistent_peers = \"\"/persistent_peers = \"$NODEID@localhost:36656\"/g" "$CONFIGVALIDATOR2"

# Add the validator 2 wallet to the validator 2
# The address is evmos1ed5lqrhg0qyd8mgz49xsejzhcmnterf6ls50mq
VAL2_MNEMONIC="decade release sick horse oval print canvas drastic fortune announce pioneer pitch spend galaxy stamp bridge shock skirt buffalo undo congress depend chimney region"
# Import keys from mnemonics
echo "$VAL2_MNEMONIC" | evmosd keys add "$VAL_KEY" --recover --keyring-backend "$KEYRING" --algo "$KEYALGO" --home "$HOMEDIRVALIDATOR2"

