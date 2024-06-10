#!/bin/bash

BASEFOLDER=$(pwd)
HOMEDIR="$BASEFOLDER/validator-folder"

# Start the node
evmosd tx bank send mykey evmos1ed5lqrhg0qyd8mgz49xsejzhcmnterf6ls50mq 100evmos --home "$HOMEDIR" --node http://localhost:36657 --fees 0.1evmos -y

