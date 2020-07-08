
all: $(PROJ).rpt $(PROJ).bin

%.blif: %.v $(ADD_SRC) $(ADD_DEPS)
	yosys -ql $*.log $(if $(USE_ARACHNEPNR),-DUSE_ARACHNEPNR) -p 'synth_ice40 -top top -blif $@' $< $(ADD_SRC)

%.json: %.v $(ADD_SRC) $(ADD_DEPS)
	verilator --top-module top $< $(ADD_SRC) --lint-only -Wall -Wno-DECLFILENAME
	yosys -ql $*.log $(if $(USE_ARACHNEPNR),-DUSE_ARACHNEPNR) -p 'synth_ice40 $(ADD_YOSYS) -top top -json $@' $< $(ADD_SRC)

ifeq ($(USE_ARACHNEPNR),)
%.asc: $(PIN_DEF) %.json
	nextpnr-ice40 --$(DEVICE) $(if $(PACKAGE),--package $(PACKAGE)) $(if $(FREQ),--freq $(FREQ)) --json $(filter-out $<,$^) --pcf $< --asc $@
else
%.asc: $(PIN_DEF) %.blif
	arachne-pnr -d $(subst up,,$(subst hx,,$(subst lp,,$(DEVICE)))) $(if $(PACKAGE),-P $(PACKAGE)) -o $@ -p $^
endif


%.bin: %.asc
	icepack $< $@

%.rpt: %.asc
	icetime $(if $(FREQ),-c $(FREQ)) -d $(DEVICE) -mtr $@ $<

%_tb: %_tb.v %.v
	verilator -DSIMULATION --top-module top $(PROJ).v $(ADD_SRC) --lint-only -Wall -Wno-DECLFILENAME
	iverilog -DSIMULATION -g2012 -o $@ $(ADD_SRC) $^
	./$@
	#gtkwave $(PROJ).vcd $(PROJ).gtkw &

%_tb.vcd: %_tb
	vvp -N $< +vcd=$@

%_syn.v: %.blif
	yosys -p 'read_blif -wideports $^; write_verilog $@'

%_syntb: %_tb.v %_syn.v
	verilator --top-module top $< $(ADD_SRC) --lint-only -Wall -Wno-DECLFILENAME
	iverilog -o $@ $^ `yosys-config --datdir/ice40/cells_sim.v`

%_syntb.vcd: %_syntb
	vvp -N $< +vcd=$@

prog: $(PROJ).bin
	iceprog $<

clean:
	rm -f $(PROJ).blif $(PROJ).asc $(PROJ).rpt $(PROJ).bin $(PROJ).json $(PROJ).log *.vvp *.vcd $(ADD_CLEAN)

.SECONDARY:
.PHONY: all prog clean
