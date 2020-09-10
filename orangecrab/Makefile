
CROSS=riscv32-unknown-elf-

ifndef SERV
S = https://github.com/olofk/serv
$(error SERV is not set, see $(S))
endif

ifndef SOC
S = https://github.com/DaveBerkeley/serv_soc
$(error SOC is not set, see $(S))
endif

BUILD = build
PROJ  = crab
LPF = orangecrab_r02.lpf


# C files

CFILES  = firmware.c

# Verilog files

FILES =
FILES += orangecrab.v

# DSP Files

DSP=../dsp

FILES += $(DSP)/dsp.v
FILES += $(DSP)/audio_engine.v
FILES += $(DSP)/dpram.v
FILES += $(DSP)/i2s_rx.v
FILES += $(DSP)/i2s_tx.v
FILES += $(DSP)/i2s_clock.v
FILES += $(DSP)/i2s_secondary.v
FILES += $(DSP)/pipe.v
FILES += $(DSP)/sequencer.v
FILES += $(DSP)/multiplier.v
FILES += $(DSP)/shifter.v
FILES += $(DSP)/accumulator.v
FILES += $(DSP)/addr_adder.v
FILES += $(DSP)/twos_complement.v

# Serv SoC Files
FILES += $(SOC)/reset.v
FILES += $(SOC)/ibus.v
FILES += $(SOC)/uart.v
FILES += $(SOC)/spi.v
FILES += $(SOC)/gpio.v
FILES += $(SOC)/chip_select.v
FILES += $(SOC)/ram_arb.v
FILES += $(SOC)/bus_arb.v
FILES += $(SOC)/timer.v
FILES += $(SOC)/irq.v

#HW_FILES += $(SOC)/ram.v
HW_FILES += ram.v

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

FILES += $(CPU_FILES)

CORE=$(SERV)/rtl

VCONFIG = /tmp/$(PROJ)_config.vlt

SIM_FILES = 
SIM_FILES += $(SOC)/sim.v

ADD_VERILATOR = $(VCONFIG) +incdir+$(CORE) $(SIM_FILES)

all: $(BUILD)/firmware.bin $(BUILD)/$(PROJ).bit

clean:
	rm -rf pll.v $(BUILD) $(VCONFIG)

pll.v: Makefile
	icepll -o 30 -m -f pll.v

$(BUILD)/$(PROJ).bit: $(FILES) Makefile $(VCONFIG) $(LPF)
	verilator --top-module top $(ADD_VERILATOR) $(FILES) --lint-only -Wall
	./make.py $(FILES) $(HW_FILES) --tool trellis --project $(PROJ) --lpf $(LPF)

dfu: $(BUILD)/$(PROJ).bit
	cp -a $(BUILD)/$(PROJ).bit $(BUILD)/$(PROJ).dfu
	dfu-suffix -v 1209 -p 5af0 -a $(BUILD)/$(PROJ).dfu
	dfu-util -D $(BUILD)/$(PROJ).dfu

$(VCONFIG): config.vlt
	envsubst < $^ > $@

$(BUILD)/firmware.bin: $(BUILD)/firmware.elf
	$(CROSS)objcopy -S -O binary $^ $@

CFLAGS  = -DICEBREAKER
CFLAGS += -march=rv32i
CFLAGS += -ffreestanding
CFLAGS += -nostartfiles
CFLAGS += -Wall -Werror
CFLAGS += -O1
CFLAGS += -I $(SOC)
CFLAGS += $(SHARED_DEFINES)
LFLAGS = -Wl,-Bstatic,-T,cpu_sections.lds,--strip-debug 

$(BUILD)/firmware.elf: $(CFILES) $(SOC)/start.s $(SOC)/soc.c Makefile cpu_sections.lds
	mkdir -p $(BUILD)
	$(CROSS)g++ $(CFLAGS) $(LFLAGS) -o $@ $(SOC)/start.s $(SOC)/soc.c $(CFILES)

#	FIN
