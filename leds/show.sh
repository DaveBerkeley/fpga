#!/bin/bash

iverilog -o leds.vvp leds.v leds_tb.v

ERR=$?

case $ERR in
    0) {
        echo "okay";
    };;
    *) {
        exit $ERR;
    };;
esac

./leds.vvp 

gtkwave leds.vcd leds.gtkw &

# FIN
