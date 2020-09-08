
all: orangecrab.json

clean:
	rm -rf *.log pll.v *.json build

orangecrab.json:
	yosys -ql orangecrab.log -p 'synth_ecp5 -top top -json orangecrab.json' orangecrab.v  

pll.v: Makefile
	icepll -o 30 -m -f pll.v

#icepll -o 30 -m -f pll.v
#CKAGEPIN/g' pll.v
#envsubst < config.vlt > /tmp/orangecrab_config.vlt
#verilator --top-module top /tmp/orangecrab_config.vlt +incdir+/home/dave/Desktop/serv/rtl +define+USE_SK9822 orangecrab.v  /home/dave/Desktop/serv/rtl/serv_rf_top.v /home/dave/Desktop/serv/rtl/serv_rf_ram_if.v /home/dave/Desktop/serv/rtl/serv_rf_ram.v /home/dave/Desktop/serv/rtl/serv_rf_if.v /home/dave/Desktop/serv/rtl/serv_mem_if.v /home/dave/Desktop/serv/rtl/serv_top.v /home/dave/Desktop/serv/rtl/serv_state.v /home/dave/Desktop/serv/rtl/serv_decode.v /home/dave/Desktop/serv/rtl/serv_bufreg.v /home/dave/Desktop/serv/rtl/serv_ctrl.v /home/dave/Desktop/serv/rtl/serv_alu.v /home/dave/Desktop/serv/rtl/serv_shift.v /home/dave/Desktop/serv/rtl/serv_csr.v pll.v audio_engine.v dpram.v i2s_tx.v i2s_rx.v i2s_clock.v i2s_secondary.v sequencer.v pipe.v shifter.v accumulator.v multiplier.v twos_complement.v addr_adder.v spl.v dma.v sk9822.v agc.v /home/dave/Desktop/git/serv_soc/src/reset.v /home/dave/Desktop/git/serv_soc/src/ibus.v /home/dave/Desktop/git/serv_soc/src/uart.v /home/dave/Desktop/git/serv_soc/src/spi.v /home/dave/Desktop/git/serv_soc/src/gpio.v /home/dave/Desktop/git/serv_soc/src/chip_select.v /home/dave/Desktop/git/serv_soc/src/ram_arb.v /home/dave/Desktop/git/serv_soc/src/bus_arb.v /home/dave/Desktop/git/serv_soc/src/timer.v /home/dave/Desktop/git/serv_soc/src/irq.v /home/dave/Desktop/git/serv_soc/src/ice40up5k_spram.v /home/dave/Desktop/git/serv_soc/src/ram.v icebreaker.v /usr/share/yosys/ice40/cells_sim.v --lint-only -Wall 

