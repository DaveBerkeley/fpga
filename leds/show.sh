#!/bin/bash

iverilog -o leds.vvp top.v leds.v dpram.v leds_tb.v

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
