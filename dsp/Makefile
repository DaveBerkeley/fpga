
CROSS=riscv32-unknown-elf-

ifndef SERV
S = https://github.com/olofk/serv
$(error SERV is not set, see $(S))
endif

CORE=$(SERV)/rtl

VCONFIG = /tmp/config.vlt

PROJ = dsp
ADD_SRC = 
ADD_CLEAN = pll.v firmware.elf firmware.bin firmware.hex $(PROJ).bin *_tb $(VCONFIG)
ADD_YOSYS = -dsp
ADD_VERILATOR = $(VCONFIG) +incdir+$(CORE)
ADD_DEPS = pll.v $(VCONFIG)
ADD_IVERILOG = -I $(CORE)
TB_DEPS = pll.v $(VCONFIG)
TB_VERILATOR = /usr/share/yosys/ice40/cells_sim.v $(SOC)/sim.v
ADD_TB_IVERILOG = $(SOC)/sim.v $(SOC)/tb.v

PACKAGE = sg48
DEVICE = up5k

PIN_DEF = ../icebreaker.pcf

SOC = ../serv

FILES  = pll.v
FILES += audio_engine.v
FILES += dpram.v
FILES += i2s_tx.v
FILES += i2s_rx.v
FILES += i2s_clock.v
FILES += i2s_secondary.v
FILES += sequencer.v
FILES += pipe.v
FILES += shifter.v
FILES += accumulator.v
FILES += multiplier.v
FILES += twos_complement.v
FILES += addr_adder.v

# Serv SoC Files
FILES += $(SOC)/reset.v
FILES += $(SOC)/ibus.v
FILES += $(SOC)/uart.v
FILES += $(SOC)/spi.v
FILES += $(SOC)/gpio.v
FILES += $(SOC)/chip_select.v
FILES += $(SOC)/bus_arb.v

# Files using SB_* modules we don't want in sim
HW_FILES  = $(SOC)/ice40up5k_spram.v
HW_FILES += $(SOC)/ram.v

# Serv CPU internals
CPU_FILES  = $(CORE)/serv_rf_top.v
CPU_FILES += $(CORE)/serv_rf_ram_if.v
CPU_FILES += $(CORE)/serv_rf_ram.v
CPU_FILES += $(CORE)/serv_rf_if.v
CPU_FILES += $(CORE)/serv_mem_if.v
CPU_FILES += $(CORE)/serv_top.v
CPU_FILES += $(CORE)/serv_state.v
CPU_FILES += $(CORE)/serv_decode.v
CPU_FILES += $(CORE)/serv_bufreg.v
CPU_FILES += $(CORE)/serv_ctrl.v
CPU_FILES += $(CORE)/serv_alu.v
CPU_FILES += $(CORE)/serv_shift.v
CPU_FILES += $(CORE)/serv_csr.v

ADD_SRC   += $(CPU_FILES) $(FILES) $(HW_FILES)
TB_SRC     = $(CPU_FILES) $(FILES)


include ../main.mk

prog_firmware: firmware.bin
	iceprog -o 1M $^

all: prog_firmware prog

pll.v : Makefile
	icepll -o 32 -m -f $@
	# Change *_CORE macro to *_PAD macro
	# See SiliconBlue ICE TM Technology Library Version 2.3
	sed -i 's/SB_PLL40_CORE/SB_PLL40_PAD/g' $@
	sed -i 's/.REFERENCECLK/.PACKAGEPIN/g' $@

firmware.bin: firmware.elf
	$(CROSS)objcopy -S -O binary $^ $@

CFLAGS  = -DICEBREAKER
CFLAGS += -march=rv32i
CFLAGS += -ffreestanding
CFLAGS += -nostartfiles
CFLAGS += -Wall -Werror
CFLAGS += -O1
LFLAGS = -Wl,-Bstatic,-T,icebreaker_sections.lds,--strip-debug 

firmware.elf: firmware.c engine.c $(SOC)/start.s Makefile icebreaker_sections.lds
	$(CROSS)g++ $(CFLAGS) $(LFLAGS) -o $@ $(SOC)/start.s firmware.c engine.c

$(VCONFIG): config.vlt
	envsubst < $^ > $@

tb: dsp_tb pipe_tb

#	FIN
