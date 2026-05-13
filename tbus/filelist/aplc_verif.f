// APLC TB Filelist
+incdir+${APLC_TB_HOME}/tb/if
+incdir+${APLC_TB_HOME}/tb/uvc/spi_agent

// UVM
${VCS_HOME}/etc/uvm-1.2/src/uvm_pkg.sv

// SPI VIP
${APLC_TB_HOME}/tb/uvc/spi_agent/aplc_spi_if.sv
${APLC_TB_HOME}/tb/uvc/spi_agent/aplc_spi_pkg.sv

// TB
${APLC_TB_HOME}/tb/if/aplc_csr_if.sv
${APLC_TB_HOME}/tb/env/aplc_tb_pkg.sv
${APLC_TB_HOME}/tb/tb_top.sv

// Test cases
${APLC_TB_HOME}/tc/aplc_base_test.sv
${APLC_TB_HOME}/tc/aplc_smoke_test.sv

// DUT RTL
${APLC_RTL_HOME}/APLC_LITE.sv
${APLC_RTL_HOME}/SLC_TASKALLO.sv
${APLC_RTL_HOME}/SLC_BANK.sv
${APLC_RTL_HOME}/SLC_CAXIS.sv
${APLC_RTL_HOME}/SLC_DPCHK.sv
${APLC_RTL_HOME}/SLC_CCMD.sv
${APLC_RTL_HOME}/SLC_CSRFILE.sv
${APLC_RTL_HOME}/SLC_DPIPE.sv
${APLC_RTL_HOME}/SLC_SAXIM.sv
${APLC_RTL_HOME}/SLC_SAXIS.sv
${APLC_RTL_HOME}/SLC_SCTRL_FRONT.sv
${APLC_RTL_HOME}/SLC_SCTRL_BACK.sv
${APLC_RTL_HOME}/SLC_TPIPE.sv
${APLC_RTL_HOME}/SLC_RXFIFO.sv
${APLC_RTL_HOME}/SLC_TXFIFO.sv
${APLC_RTL_HOME}/SLC_WBB.sv
