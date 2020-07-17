PROJ = wavegen
ADD_SRC = ../dsp/i2s_clock.v ../dsp/i2s_tx.v ../dsp/i2s_secondary.v
ADD_CLEAN = wave.v  wavegen_tb
ADD_DEPS = wave.v
ADD_YOSYS = 
ADD_VERILATOR = config.vlt
ADD_IVERILOG = $(PROJ).v

TB_SRC = ../dsp/i2s_clock.v ../dsp/i2s_tx.v ../dsp/i2s_secondary.v 

PACKAGE = tq144:4k
DEVICE = hx8k 

PIN_DEF = ../alhambra-ii.pcf

include ../main.mk

wave.v : wave.py
	./wave.py > wave.v

