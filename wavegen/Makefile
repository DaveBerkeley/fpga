PROJ = wavegen
ADD_SRC = uart.v ../mems/i2s_clock.v ../mems/i2s_tx.v pll.v ../dsp/i2s_secondary.v
ADD_CLEAN = wave.v  pll.v
ADD_DEPS = wave.v pll.v
ADD_YOSYS = 
ADD_VERILATOR = config.vlt

PACKAGE = tq144:4k
DEVICE = hx8k 

PIN_DEF = ../alhambra-ii.pcf

include ../main.mk

wave.v : wave.py
	./wave.py > wave.v

pll.v : Makefile
	icepll -o 45.16 -m -f pll.v

