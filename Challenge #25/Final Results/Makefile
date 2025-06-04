# Language and simulator
TOPLEVEL_LANG = verilog
SIM = verilator

# Verilog source files
VERILOG_SOURCES = $(shell pwd)/qr_wrapper.v \
                  $(shell pwd)/qr_spi_top.v \
                  $(shell pwd)/qr_verilog_modules.v

# Top-level Verilog module
TOPLEVEL = qr_wrapper

# Python testbench module (without .py extension)
MODULE = cocotb_testbench

# Enable waveform tracing
WAVES = 1
EXTRA_ARGS += --trace
# Verilator warning suppression and error limits
EXTRA_ARGS += --Wno-fatal
EXTRA_ARGS += --error-limit 0
EXTRA_ARGS += --Wno-UNOPTFLAT --Wno-WIDTH --Wno-STMTDLY --Wno-UNUSED


# Python environment
export PYTHONPATH := $(shell pwd)
export COCOTB_RESOLVE_MODULES := 1

# Default target
all: sim

# Run simulation with explicitly resolved Makefile
MAKEFILE_PATH := $(shell cocotb-config --makefile)/Makefile.sim

sim:
	@echo "Running simulation..."
	make -f $(MAKEFILE_PATH) \
		SIM=$(SIM) \
		MODULE=$(MODULE) \
		TOPLEVEL=$(TOPLEVEL) \
		TOPLEVEL_LANG=$(TOPLEVEL_LANG) \
		EXTRA_ARGS="$(EXTRA_ARGS)" \
		VERILOG_SOURCES="$(VERILOG_SOURCES)"

clean:
	rm -rf sim_build __pycache__ results.xml

.PHONY: all clean sim



