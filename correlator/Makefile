PROJ = correlator
ADD_SRC = ../dsp/dpram.v ../dsp/iomem.v ../dsp/multiplier.v ../dsp/accumulator.v ../dsp/shifter.v ../dsp/gpio.v ../dsp/twos_complement.v ../dsp/pipe.v mac.v
ADD_CLEAN = correlator_tb correlator_syntb correlator_syn.v *_tb *.vcd
ADD_YOSYS = -dsp
ADD_VERILATOR = config.vlt
ADD_IVERILOG = correlator.v

PACKAGE = sg48
DEVICE = up5k

PIN_DEF = ../icebreaker.pcf

#TB_SRC = $(filter-out pll.v, $(ADD_SRC))
TB_SRC = $(ADD_SRC)

include ../main.mk


