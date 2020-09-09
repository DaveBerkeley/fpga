
BUILD = build
PROJ  = blinky

all: $(BUILD)/$(PROJ).bit

clean:
	rm -rf pll.v $(BUILD)

#pll.v: Makefile
#	icepll -o 30 -m -f pll.v

FILES =
FILES += orangecrab.v

$(BUILD)/$(PROJ).bit: $(FILES) Makefile
	./make.py $(FILES) --tool trellis --project $(PROJ) --lpf orangecrab_r02.lpf

dfu: $(BUILD)/$(PROJ).bit
	cp -a $(BUILD)/$(PROJ).bit $(BUILD)/$(PROJ).dfu
	dfu-suffix -v 1209 -p 5af0 -a $(BUILD)/$(PROJ).dfu
	dfu-util -D $(BUILD)/$(PROJ).dfu

