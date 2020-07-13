PROJ = dsp
ADD_SRC = dpram.v audio_engine.v sequencer.v iomem.v multiplier.v accumulator.v shifter.v addr_adder.v gpio.v i2s_clock.v i2s_tx.v i2s_rx.v pll.v
ADD_CLEAN = dsp_tb dsp_syntb dsp_syn.v *_tb *.vcd
ADD_YOSYS = -dsp
ADD_VERILATOR = config.vlt

PACKAGE = sg48
DEVICE = up5k

PIN_DEF = ../icebreaker.pcf

TB_SRC = $(filter-out pll.v, $(ADD_SRC)) i2s_secondary.v

include ../main.mk

iomem_tb: iomem.v iomem_tb.v
	# verilator --top-module top $^ --lint-only -Wall -Wno-DECLFILENAME -Wno-STMTDLY
	iverilog -DSIMULATION -g2012 -o $@ $^
	./$@

pll.v : Makefile
	icepll -o 45.16 -m -f pll.v

