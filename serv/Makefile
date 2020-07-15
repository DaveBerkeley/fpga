
PROJ = serv
ADD_SRC = pll.v 
ADD_CLEAN = dsp_tb dsp_syntb dsp_syn.v *_tb *.vcd
ADD_YOSYS = -dsp
ADD_VERILATOR = config.vlt

PACKAGE = sg48
DEVICE = up5k

PIN_DEF = ../icebreaker.pcf

#SERV=/home/dave/Desktop/serv
SERVANT=$(SERV)/servant

FILES=$(SERVANT)/servant.v
FILES+=$(SERVANT)/service.v
FILES+=$(SERVANT)/servant_arbiter.v
FILES+=$(SERVANT)/servant_mux.v
FILES+=$(SERVANT)/servant_ram.v
FILES+=$(SERVANT)/servant_timer.v
FILES+=$(SERVANT)/servant_gpio.v
FILES+=$(SERVANT)/servant_clock_gen.v

CORE=$(SERV)/rtl
FILES+=$(CORE)/serv_rf_top.v
FILES+=$(CORE)/serv_rf_ram_if.v
FILES+=$(CORE)/serv_rf_ram.v
FILES+=$(CORE)/serv_rf_if.v
FILES+=$(CORE)/serv_mem_if.v
FILES+=$(CORE)/serv_top.v
FILES+=$(CORE)/serv_state.v
FILES+=$(CORE)/serv_decode.v
FILES+=$(CORE)/serv_bufreg.v
FILES+=$(CORE)/serv_ctrl.v
FILES+=$(CORE)/serv_alu.v
FILES+=$(CORE)/serv_shift.v
FILES+=$(CORE)/serv_csr.v

ADD_SRC+=$(FILES)

#TB_SRC = $(filter-out pll.v, $(ADD_SRC)) i2s_secondary.v

include ../main.mk

pll.v : Makefile
	icepll -o 16 -m -f pll.v
	# Change from the CORE macro to the PAD macro
	# See SiliconBlue ICE TM Technology Library Version 2.3
	sed -i 's/SB_PLL40_CORE/SB_PLL40_PAD/g' pll.v
	sed -i 's/.REFERENCECLK/.PACKAGEPIN/g' pll.v

