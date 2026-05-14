# AI gen: APLC-Lite VIP Compilation Makefile
# Usage:
#   make comp       - Compile VIP files only
#   make comp_vip   - Compile VIP agent/sequence/if files (no env/tb_top)
#   make clean      - Clean build artifacts

# -------------------- Configuration --------------------
VCS       = vcs
SCRIPT_DIR    := $(shell pwd)
APLC_TB_HOME  := $(SCRIPT_DIR)/..
DV_ROOT       := $(SCRIPT_DIR)/../..

export APLC_TB_HOME
export DV_ROOT

SIM_DIR  ?= sim_work

# -------------------- VCS Options --------------------
VCS_COMP_OPTS = \
    -full64 \
    -sverilog \
    -debug_access+all \
    -kdb \
    -lca \
    +incdir+$(APLC_TB_HOME)/tb/if \
    +incdir+$(APLC_TB_HOME)/tb/uvc/spi_agent \
    +incdir+$(APLC_TB_HOME)/tb/uvc/csr_agent \
    +incdir+$(APLC_TB_HOME)/tb/uvc/fifo_agent \
    +incdir+$(APLC_TB_HOME)/tb/env \
    +incdir+$(APLC_TB_HOME)/seq \
    -timescale=1ns/1ps \
    -ntb_opts uvm-1.2 \
    +define+UVM_NO_DPI \
    +define+ASSERT_ON \
    -LDFLAGS -Wl,--no-as-needed \
    -l compile.log

# -------------------- VIP-only file list --------------------
VIP_FILES = \
    $(APLC_TB_HOME)/tb/if/spi_if.sv \
    $(APLC_TB_HOME)/tb/if/csr_if.sv \
    $(APLC_TB_HOME)/tb/if/fifo_if.sv \
    $(APLC_TB_HOME)/tb/uvc/spi_agent/spi_defines.sv \
    $(APLC_TB_HOME)/tb/uvc/spi_agent/spi_transaction.sv \
    $(APLC_TB_HOME)/tb/uvc/spi_agent/spi_agent_cfg.sv \
    $(APLC_TB_HOME)/tb/uvc/spi_agent/spi_driver.sv \
    $(APLC_TB_HOME)/tb/uvc/spi_agent/spi_monitor.sv \
    $(APLC_TB_HOME)/tb/uvc/spi_agent/spi_sequencer.sv \
    $(APLC_TB_HOME)/tb/uvc/spi_agent/spi_agent.sv \
    $(APLC_TB_HOME)/tb/uvc/csr_agent/csr_defines.sv \
    $(APLC_TB_HOME)/tb/uvc/csr_agent/csr_transaction.sv \
    $(APLC_TB_HOME)/tb/uvc/csr_agent/csr_agent_cfg.sv \
    $(APLC_TB_HOME)/tb/uvc/csr_agent/csr_monitor.sv \
    $(APLC_TB_HOME)/tb/uvc/csr_agent/csr_agent.sv \
    $(APLC_TB_HOME)/tb/uvc/fifo_agent/fifo_defines.sv \
    $(APLC_TB_HOME)/tb/uvc/fifo_agent/fifo_transaction.sv \
    $(APLC_TB_HOME)/tb/uvc/fifo_agent/fifo_agent_cfg.sv \
    $(APLC_TB_HOME)/tb/uvc/fifo_agent/fifo_monitor.sv \
    $(APLC_TB_HOME)/tb/uvc/fifo_agent/fifo_agent.sv \
    $(APLC_TB_HOME)/seq/spi_base_seq.sv

# -------------------- Targets --------------------
.PHONY: comp comp_vip clean

comp:
	@mkdir -p $(SIM_DIR)
	cd $(SIM_DIR) && $(VCS) $(VCS_COMP_OPTS) -f $(APLC_TB_HOME)/filelist/APLC_LITE_verif.f

comp_vip:
	@mkdir -p $(SIM_DIR)
	cd $(SIM_DIR) && $(VCS) $(VCS_COMP_OPTS) $(VIP_FILES)

clean:
	rm -rf $(SIM_DIR)
	rm -rf csrc simv* vc_hdrs.h ucli.key *.log *.vpd *.key *.vdb DVEfiles novas* *.fsdb verdiLog
