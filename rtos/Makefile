
CROSS=riscv32-unknown-elf-

ifndef SERV
S = https://github.com/olofk/serv
$(error SERV is not set, see $(S))
endif

ifndef SOC
S = https://github.com/DaveBerkeley/serv_soc
$(error SOC is not set, see $(S))
endif

CORE=$(SERV)/rtl

PROJ = rtos
ADD_SRC = 
ADD_CLEAN =  pll.v firmware.elf firmware.bin firmware.hex $(PROJ).bin *_tb
ADD_CLEAN += build/rtos/* build/port/* build/rtos.a build/obj/* build/soc/* 
ADD_YOSYS = -dsp
ADD_VERILATOR = $(VCONFIG) +incdir+$(CORE)
ADD_DEPS = pll.v $(VCONFIG)
ADD_IVERILOG = -I $(CORE)
TB_DEPS = pll.v $(VCONFIG)
TB_VERILATOR = /usr/share/yosys/ice40/cells_sim.v $(SOC)/sim.v
ADD_TB_IVERILOG = $(SOC)/sim.v $(SOC)/tb.v

VCONFIG = /tmp/$(PROJ)_config.vlt

PACKAGE = sg48
DEVICE = up5k

DEFINES  = 
#DEFINES += MAKE_DSP

# -D<symbol> syntax common to yosys and gcc
SHARED_DEFINES = $(DEFINES:%=-D %)
MORE_YOSYS = $(SHARED_DEFINES)
ADD_VERILATOR += $(DEFINES:%=+define+%)

PLL_MHZ = 25.0
PLL_HZ = 25000000

PIN_DEF = ../icebreaker.pcf

FILES  = pll.v
FILES += dpram.v

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

# Files using SB_* modules we don't want in sim
HW_FILES  = $(SOC)/ice40up5k_spram.v
HW_FILES += $(SOC)/ram.v
HW_FILES += icebreaker.v

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
CPU_FILES += $(CORE)/serv_immdec.v

ADD_SRC   += $(CPU_FILES) $(FILES) $(HW_FILES)
TB_SRC     = $(CPU_FILES) $(FILES)

include ../main.mk

prog_firmware: firmware.bin
	iceprog -o 1M $^

all: prog_firmware prog

pll.v : Makefile
	icepll -o $(PLL_MHZ) -m -f $@
	# Change *_CORE macro to *_PAD macro
	# See SiliconBlue ICE TM Technology Library Version 2.3
	sed -i 's/SB_PLL40_CORE/SB_PLL40_PAD/g' $@
	sed -i 's/.REFERENCECLK/.PACKAGEPIN/g' $@

#
#

firmware.bin: firmware.elf
	$(CROSS)objcopy -S -O binary $^ $@

C_ARCH = -march=rv32i

CFLAGS  = -DICEBREAKER
CFLAGS += $(C_ARCH)
CFLAGS += -Wall -Werror
CFLAGS += -O1
CFLAGS += -I $(SOC)
CFLAGS += $(SHARED_DEFINES)
LFLAGS = -Wl,-Bstatic,-T,icebreaker_sections.lds,--strip-debug 
LFLAGS += -ffreestanding
LFLAGS += -nostartfiles

CFILES = firmware.c

# Add FreeRTOS files
PORT = portable/GCC/RISC-V

# FreeRTOS Files
RTOS_FILES = 
RTOS_FILES += $(FREERTOS)/tasks.c
RTOS_FILES += $(FREERTOS)/list.c

# SoC Port Files
RTOS_PORT =
RTOS_PORT += $(PORT)/stub.c
RTOS_PORT += $(PORT)/port.c

RCFLAGS = $(C_ARCH) -Wall -Werror -O1
RCFLAGS += -I $(PORT)
RCFLAGS += -I .
RCFLAGS += -I $(FREERTOS)/include/
RCFLAGS += -I $(SOC)

build:
	mkdir -p build/rtos
	mkdir -p build/port
	mkdir -p build/obj
	mkdir -p build/soc

RTOS_SRC =  $(notdir $(RTOS_FILES))
RTOS_OBJ =  $(RTOS_SRC:%.c=build/rtos/%.o)
RTOS_OBJ += build/port/portASM.o

RTOS_PORT_SRC = $(notdir $(RTOS_PORT))
RTOS_PORT_OBJ = $(RTOS_PORT_SRC:%.c=build/port/%.o)

build/rtos/%.o : 
	$(CROSS)gcc $(RCFLAGS) -o build/rtos/$(notdir $@) -c $(FREERTOS)/$(*F).c

build/port/%.o : $(RTOS_PORT)
	$(CROSS)gcc $(RCFLAGS) -o build/port/$(notdir $@) -c $(PORT)/$(*F).c

build/port/portASM.o: $(PORT)/portASM.S
	$(CROSS)gcc $(RCFLAGS) -o build/port/$(notdir $@) -c $<

#	Free RTOS Library

build/rtos.a: $(RTOS_OBJ) $(RTOS_PORT_OBJ) Makefile
	$(CROSS)ar rcs $@ $(RTOS_OBJ) $(RTOS_PORT_OBJ)

#	SoC code

SOC_FILES =
SOC_FILES += $(SOC)/soc.c
SOC_SRC = $(notdir $(SOC_FILES))
SOC_OBJ = $(SOC_SRC:%.c=build/soc/%.o)

build/soc/%.o: $(SOC_FILES)
	$(CROSS)g++ $(CFLAGS) -o build/soc/$(notdir $@) -c $<

build/soc/start.o: $(SOC)/start.s
	$(CROSS)g++ $(CFLAGS) -o build/soc/$(notdir $@) -c $<

#	C Source

OBJ = $(CFILES:%.c=build/obj/%.o)
	
build/obj/%.o: $(CFILES)
	$(CROSS)g++ $(CFLAGS) -o build/obj/$(notdir $@) -c $<

#
#

firmware.elf: build $(OBJ) $(SOC_OBJ) build/soc/start.o Makefile icebreaker_sections.lds build/rtos.a
	$(CROSS)g++ $(CFLAGS) $(LFLAGS) -o $@ build/soc/start.o $(SOC_OBJ) $(OBJ) -L build/rtos.a

$(VCONFIG): config.vlt
	envsubst < $^ > $@

tb:  

#	FIN
