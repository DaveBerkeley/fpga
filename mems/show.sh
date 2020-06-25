#!/bin/bash

# verilator i2s_rx.v i2s_tx.v i2s_clock.v dpram.v i2s_tb.v --lint-only -Wall -Wno-DECLFILENAME

iverilog -o i2s.vvp i2s_rx.v i2s_tx.v i2s_clock.v dpram.v i2s_tb.v

ERR=$?

case $ERR in
    0) {
        echo "okay";
    };;
    *) {
        exit $ERR;
    };;
esac

./i2s.vvp 

gtkwave i2s.vcd mems.gtkw &

# FIN
