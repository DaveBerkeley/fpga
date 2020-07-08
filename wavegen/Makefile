PROJ = wavegen
ADD_SRC = uart.v ../mems/i2s_clock.v 
ADD_CLEAN = wave.v 
ADD_DEPS = wave.v
ADD_YOSYS = 

PACKAGE = tq144:4k
DEVICE = hx8k 

PIN_DEF = ../alhambra-ii.pcf

include ../main.mk

wave.v : wave.py
	./wave.py > wave.v

