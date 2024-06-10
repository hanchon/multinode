#!/bin/bash
BASEFOLDER=$(pwd)
HOMEDIRVALIDATOR2="$BASEFOLDER/validator2-folder"

# Send the create validator transaction
evmosd tx staking create-validator \
  --pubkey=$(evmosd tendermint show-validator --home "$HOMEDIRVALIDATOR2") \
  --amount=1evmos \
  --moniker="validator2" \
  --chain-id="evmos_9000-1" \
  --commission-rate="0.05" \
  --commission-max-rate="0.10" \
  --commission-max-change-rate="0.01" \
  --min-self-delegation="1000000" \
  --from=mykey \
  --node http://localhost:36657 \
  --fees 0.5evmos \
  --gas 500000\
  --home "$HOMEDIRVALIDATOR2" \
  -y
