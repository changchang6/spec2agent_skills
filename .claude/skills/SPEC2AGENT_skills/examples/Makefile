# APLC-Lite UVM Testbench Makefile
# Usage:
#   make comp        - Compile the VIP
#   make clean       - Clean build artifacts

# -------------------- Configuration --------------------
VCS       = vcs
SCRIPT_DIR    := $(shell pwd)
VIP_HOME  := $(SCRIPT_DIR)

export VIP_HOME

SIM_DIR  ?= sim_work

# -------------------- VCS Options --------------------
VCS_COMP_OPTS = \
    -full64 \
    -sverilog \
    -debug_access+all \
    -kdb \
    -lca \
    +incdir+$(VIP_HOME) \
    -timescale=1ns/1ps \
    -ntb_opts uvm-1.2 \
    +define+UVM_NO_DPI \
    -LDFLAGS -Wl,--no-as-needed \
    -l compile.log

# -------------------- Targets --------------------
.PHONY: comp clean

comp:
	@echo "Compiling VIP..."
	$(VCS) $(VCS_COMP_OPTS) \
		$(VIP_HOME)/spi_if.sv \
		$(VIP_HOME)/spi_pkg.sv
	@echo "SPI VIP compilation completed successfully"

clean:
	rm -rf $(SIM_DIR)
	rm -rf csrc simv* vc_hdrs.h ucli.key *.log *.vpd *.key *.vdb DVEfiles novas* *.fsdb verdiLog
    @echo "Clean completed"
