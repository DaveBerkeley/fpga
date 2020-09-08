
BUILD=build

all: $(BUILD)/blinky.bit

clean:
	rm -rf *.log pll.v *.json build

#pll.v: Makefile
#	icepll -o 30 -m -f pll.v

$(BUILD)/blinky.bit: orangecrab.v
	./make.py

dfu: $(BUILD)/blinky.bit
	cp -a $(BUILD)/blinky.bit $(BUILD)/blinky.dfu
	dfu-suffix -v 1209 -p 5af0 -a $(BUILD)/blinky.dfu
	dfu-util -D $(BUILD)/blinky.dfu

