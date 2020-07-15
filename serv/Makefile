
CROSS=riscv32-unknown-elf-

#SERV=/home/dave/Desktop/serv
SERVANT=$(SERV)/servant
CORE=$(SERV)/rtl

PROJ = serv
ADD_SRC = pll.v 
ADD_CLEAN = pll.v firmware.elf firmware.bin $(PROJ).bin serv.hex
ADD_YOSYS = -dsp
ADD_VERILATOR = config.vlt +incdir+$(CORE)
ADD_DEPS = firmware.hex

PACKAGE = sg48
DEVICE = up5k

PIN_DEF = ../icebreaker.pcf

FILES =$(SERVANT)/servant.v
FILES+=$(SERVANT)/service.v
FILES+=$(SERVANT)/servant_arbiter.v
FILES+=$(SERVANT)/servant_mux.v
FILES+=$(SERVANT)/servant_ram.v
FILES+=$(SERVANT)/servant_timer.v
FILES+=$(SERVANT)/servant_gpio.v
FILES+=$(SERVANT)/servant_clock_gen.v

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
#VERILATOR_SRC = $(filter-out pll.v, $(ADD_SRC))
VERILATOR_SRC = $(filter-out $(wildcard *servant*.c), $(ADD_SRC))

include ../main.mk

pll.v : Makefile
	icepll -o 16 -m -f pll.v
	# Change from the CORE macro to the PAD macro
	# See SiliconBlue ICE TM Technology Library Version 2.3
	sed -i 's/SB_PLL40_CORE/SB_PLL40_PAD/g' pll.v
	sed -i 's/.REFERENCECLK/.PACKAGEPIN/g' pll.v

# number of words in init ram
INIT_RAM_SIZE=2048

serv.hex: firmware.bin
	./makehex.py $^ $(INIT_RAM_SIZE) > $@

firmware.bin: firmware.elf
	$(CROSS)objcopy -S -O binary $^ $@

firmware.elf: firmware.c start.s Makefile
	$(CROSS)gcc -DICEBREAKER -march=rv32ic -Wl,-Bstatic,-T,icebreaker_sections.lds,--strip-debug -ffreestanding -nostdlib -o $@ start.s firmware.c

#	FIN
