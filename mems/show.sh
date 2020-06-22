#!/bin/bash

iverilog -o i2s.vvp i2s_rx.v i2s_tx.v i2s_clock.v i2s_tb.v
./i2s.vvp 
gtkwave i2s.vcd mems.gtkw &

# FIN
