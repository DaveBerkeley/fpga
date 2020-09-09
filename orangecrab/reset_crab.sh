#!/bin/bash

CRAB_POWER="home/usb/1/0"
CRAB_RESET="home/usb/1/1"

HOST="mosquitto"

OFF="R"
ON="S"

mosquitto_pub -h $HOST -t $CRAB_POWER -m $OFF

#sleep 1
#mosquitto_pub -h $HOST -t $CRAB_RESET -m $ON

sleep 1
mosquitto_pub -h $HOST -t $CRAB_POWER -m $ON

#sleep 1
#mosquitto_pub -h $HOST -t $CRAB_RESET -m $OFF

# FIN
