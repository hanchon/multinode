#!/bin/bash
BASEFOLDER=$(pwd)
HOMEDIRVALIDATOR2="$BASEFOLDER/validator2-folder"

# Start the node
evmosd start \
	--log_level info \
	--minimum-gas-prices=0.0001aevmos \
	--json-rpc.api eth,txpool,personal,net,debug,web3 \
	--json-rpc.enable true\
	--home "$HOMEDIRVALIDATOR2"

