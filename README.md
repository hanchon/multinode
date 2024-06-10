# Multinode

## Requirements

Install `evmosd` as a global binary

## Set up the genesis file with one validator

Run the init genesis script, it will create two folders in your current path with the config and data folders for 2 nodes

```sh
./init-genesis.sh
```

## Launch the validator 1

In a terminal, run the script to init the chain with the first validator

```sh
./run-validator1.sh
```

NOTE: keep the process running
NOTE2: you must be in the same folder as the first step

## Send coins the the validator 2

In a new terminal, in the same folder that you run the first script, execute the send coins script

```sh
./send-coins.sh
```

## Create the second validator

In a new terminal, in the same folder that you run the first script, execute the create validator 2 script

```sh
./create-validator-2.sh
```

## Start the validator 2

In a new terminal, in the same folder that you run the first script, execute the run validator 2 script

```sh
./run-validator2.sh
```

## Check the validator list

There should be 2 bonded validators in the validator list

```sh
evmosd q staking validators --node http://localhost:36657
```
