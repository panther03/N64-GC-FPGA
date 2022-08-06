# Makefile

# defaults
SIM ?= icarus
TOPLEVEL_LANG ?= verilog

VERILOG_SOURCES += $(PWD)/N64_Serial_top.sv $(PWD)/JOYBUS_host.sv $(PWD)/JOYBUS_rx.sv $(PWD)/JOYBUS_tx.sv $(PWD)/UART_rx.sv $(PWD)/UART_tx.sv $(PWD)/UART_host.sv $(PWD)/seven_seg_drv.sv $(PWD)/seven_seg_main.sv
# use VHDL_SOURCES for VHDL files

# TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
TOPLEVEL = N64_Serial_top

# MODULE is the basename of the Python test file
MODULE = jb_host_tb

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim