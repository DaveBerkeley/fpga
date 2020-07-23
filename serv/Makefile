
CROSS=riscv32-unknown-elf-

ifndef SERV
$(error SERV is not set)
endif

SERVANT=$(SERV)/servant
CORE=$(SERV)/rtl

VCONFIG = /tmp/config.vlt

PROJ = serv
ADD_SRC = 
ADD_CLEAN = pll.v firmware.elf firmware.bin $(PROJ).bin firmware.hex $(PROJ)_tb $(VCONFIG)
ADD_YOSYS = -dsp
ADD_VERILATOR = $(VCONFIG) +incdir+$(CORE)
ADD_DEPS = firmware.hex pll.v $(VCONFIG)
ADD_IVERILOG = -I $(CORE)
TB_DEPS = pll.v firmware.hex $(VCONFIG)
TB_VERILATOR = /usr/share/yosys/ice40/cells_sim.v

PACKAGE = sg48
DEVICE = up5k

PIN_DEF = ../icebreaker.pcf

TB_SRC = $(ADD_SRC)

FILES =  pll.v
FILES += servant.v
FILES += soc.v
FILES += uart.v
FILES += $(SERVANT)/servant_arbiter.v
FILES += servant_mux.v
FILES += $(SERVANT)/servant_ram.v
FILES += $(SERVANT)/servant_timer.v
FILES += $(SERVANT)/servant_gpio.v
FILES += $(SERVANT)/servant_clock_gen.v

FILES += $(CORE)/serv_rf_top.v
FILES += $(CORE)/serv_rf_ram_if.v
FILES += $(CORE)/serv_rf_ram.v
FILES += $(CORE)/serv_rf_if.v
FILES += $(CORE)/serv_mem_if.v
FILES += $(CORE)/serv_top.v
FILES += $(CORE)/serv_state.v
FILES += $(CORE)/serv_decode.v
FILES += $(CORE)/serv_bufreg.v
FILES += $(CORE)/serv_ctrl.v
FILES += $(CORE)/serv_alu.v
FILES += $(CORE)/serv_shift.v
FILES += $(CORE)/serv_csr.v

ADD_SRC+=$(FILES)


include ../main.mk

pll.v : Makefile
	icepll -o 32 -m -f $@
	# Change *_CORE macro to *_PAD macro
	# See SiliconBlue ICE TM Technology Library Version 2.3
	sed -i 's/SB_PLL40_CORE/SB_PLL40_PAD/g' $@
	sed -i 's/.REFERENCECLK/.PACKAGEPIN/g' $@

# number of words in init ram
INIT_RAM_SIZE=2048

firmware.hex: firmware.bin
	./makehex.py $^ $(INIT_RAM_SIZE) > $@

firmware.bin: firmware.elf
	$(CROSS)objcopy -S -O binary $^ $@

firmware.elf: firmware.c start.s Makefile
	$(CROSS)gcc -DICEBREAKER -march=rv32i -Wl,-Bstatic,-T,icebreaker_sections.lds,--strip-debug -ffreestanding -nostdlib -o $@ start.s firmware.c

$(VCONFIG): config.vlt
	envsubst < $^ > $@

#	FIN
