# SPI VIP Makefile
# Usage:
#   make comp        - Compile the SPI VIP
#   make clean        - Clean build artifacts

# -------------------- Configuration --------------------
VCS       = vcs
SCRIPT_DIR := $(shell pwd)
SPI_VIP_HOME := $(SCRIPT_DIR)

export SPI_VIP_HOME

# -------------------- VCS Options --------------------
VCS_COMP_OPTS = \
    -full64 \
    -sverilog \
    -debug_access+all \
    -kdb \
    -lca \
    +incdir+$(SPI_VIP_HOME) \
    -timescale=1ns/1ps \
    -ntb_opts uvm-1.2 \
    +define+UVM_NO_DPI \
    -LDFLAGS -Wl,--no-as-needed \
    -l compile.log

# -------------------- Targets --------------------
.PHONY: comp clean

comp:
	@echo "Compiling SPI VIP..."
	$(VCS) $(VCS_COMP_OPTS) \
		$(SPI_VIP_HOME)/spi_if.sv \
		$(SPI_VIP_HOME)/spi_pkg.sv
	@echo "SPI VIP compilation completed successfully"

clean:
	rm -rf csrc simv* vc_hdrs.h ucli.key *.log *.vpd *.key *.vdb DVEfiles novas* *.fsdb verdiLog
	rm -rf work
	@echo "Clean completed"
