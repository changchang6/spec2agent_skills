// APLC-Lite Verification File List
// Compile order for VCS

// ---- yuu_common package ----
+incdir+${APLC_TB_HOME}/vip/yuu_ahb/pkg/yuu_common/include
+incdir+${APLC_TB_HOME}/vip/yuu_ahb/pkg/yuu_common/src/sv
+define+YUU_UVM
${APLC_TB_HOME}/vip/yuu_ahb/pkg/yuu_common/include/yuu_common_pkg.sv

// ---- yuu_ahb macros and interfaces (pre-package includes) ----
+incdir+${APLC_TB_HOME}/vip/yuu_ahb/include
+incdir+${APLC_TB_HOME}/vip/yuu_ahb/src/sv
+incdir+${APLC_TB_HOME}/vip/yuu_ahb/seq
${APLC_TB_HOME}/vip/yuu_ahb/include/yuu_ahb_pkg.sv

// ---- APLC SPI VIP ----
+incdir+${APLC_TB_HOME}/vip/spi_vip
+incdir+${APLC_TB_HOME}/tb/if
+incdir+${APLC_TB_HOME}/tb/env
${APLC_TB_HOME}/vip/spi_vip/aplc_spi_if.sv
${APLC_TB_HOME}/vip/spi_vip/aplc_spi_pkg.sv

// ---- TB interfaces ----
${APLC_TB_HOME}/tb/if/aplc_csr_if.sv

// ---- TB environment ----
${APLC_TB_HOME}/tb/env/aplc_csr_file.sv
${APLC_TB_HOME}/tb/env/aplc_env_config.sv
${APLC_TB_HOME}/tb/env/aplc_env.sv

// ---- TB sequences ----
+incdir+${APLC_TB_HOME}/seq
${APLC_TB_HOME}/seq/aplc_smoke_seq.sv

// ---- TB test cases ----
+incdir+${APLC_TB_HOME}/tc
${APLC_TB_HOME}/tc/aplc_base_test.sv
${APLC_TB_HOME}/tc/aplc_smoke_test.sv

// ---- TB top ----
${APLC_TB_HOME}/tb/tb_top.sv

// ---- DUT RTL ----
+incdir+${APLC_RTL_HOME}
${APLC_RTL_HOME}/SLC_TASKALLO.sv
${APLC_RTL_HOME}/SLC_BANK.sv
${APLC_RTL_HOME}/SLC_CSRFILE.sv
${APLC_RTL_HOME}/SLC_CAXIS.sv
${APLC_RTL_HOME}/SLC_CCMD.sv
${APLC_RTL_HOME}/SLC_DPCHK.sv
${APLC_RTL_HOME}/SLC_DPIPE.sv
${APLC_RTL_HOME}/SLC_RXFIFO.sv
${APLC_RTL_HOME}/SLC_SAXIM.sv
${APLC_RTL_HOME}/SLC_SAXIS.sv
${APLC_RTL_HOME}/SLC_SCTRL_BACK.sv
${APLC_RTL_HOME}/SLC_SCTRL_FRONT.sv
${APLC_RTL_HOME}/SLC_TPIPE.sv
${APLC_RTL_HOME}/SLC_TXFIFO.sv
${APLC_RTL_HOME}/SLC_WBB.sv
${APLC_RTL_HOME}/APLC_LITE.sv
