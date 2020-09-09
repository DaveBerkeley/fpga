
BUILD = build
PROJ  = crab

VCONFIG = /tmp/$(PROJ)_config.vlt

all: $(BUILD)/$(PROJ).bit

clean:
	rm -rf pll.v $(BUILD)

#pll.v: Makefile
#	icepll -o 30 -m -f pll.v

FILES =
FILES += orangecrab.v

LPF = orangecrab_r02.lpf

$(BUILD)/$(PROJ).bit: $(FILES) Makefile $(VCONFIG) $(LPF)
	verilator $(FILES) $(VCONFIG) --lint-only -Wall
	./make.py $(FILES) --tool trellis --project $(PROJ) --lpf $(LPF)

dfu: $(BUILD)/$(PROJ).bit
	cp -a $(BUILD)/$(PROJ).bit $(BUILD)/$(PROJ).dfu
	dfu-suffix -v 1209 -p 5af0 -a $(BUILD)/$(PROJ).dfu
	dfu-util -D $(BUILD)/$(PROJ).dfu

$(VCONFIG): config.vlt
	envsubst < $^ > $@

