#!/bin/bash

iverilog -o i2s.vvp i2s.v i2s_clock.v delay.v i2s_tb.v
./i2s.vvp 
gtkwave i2s.vcd 

# FIN
