#!/bin/bash

iverilog -D SIMULATION -o mems.vvp mems.v i2s.v mems_tb.v
./mems.vvp 
gtkwave mems.vcd

# FIN
