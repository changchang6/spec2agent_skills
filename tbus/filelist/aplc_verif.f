-timescale=1ns/1ps

//-------------------------------------
// SV Define
//-------------------------------------
+define+YUU_AHB_MAX_MASTER_NUM=1
+define+YUU_AHB_MAX_SLAVE_NUM=1
+define+YUU_AHB_MAX_ADDR_WIDTH=32
+define+YUU_AHB_MAX_DATA_WIDTH=32
+define+YUU_UVM
+define+DUMP_FSDB

//-------------------------------------
// SV Include
//-------------------------------------
+incdir+${APLC_TB_HOME}/tb/if
+incdir+${APLC_TB_HOME}/tb/env
+incdir+${APLC_TB_HOME}/seq
+incdir+${APLC_TB_HOME}/tc
+incdir+${APLC_TB_HOME}/../vip/spi
+incdir+${APLC_TB_HOME}/../vip/yuu_ahb/include
+incdir+${APLC_TB_HOME}/../vip/yuu_ahb/src/sv
+incdir+${APLC_TB_HOME}/../vip/yuu_ahb/seq
+incdir+${APLC_TB_HOME}/../vip/yuu_ahb/pkg/yuu_common/include
+incdir+${APLC_TB_HOME}/../vip/yuu_ahb/pkg/yuu_common/src/sv
+incdir+${APLC_TB_HOME}/../vip/yuu_ahb/pkg/yuu_amba/include
+incdir+${APLC_TB_HOME}/../vip/yuu_ahb/pkg/yuu_amba/src/sv

//-------------------------------------
// UVM
//-------------------------------------
${VCS_HOME}/etc/uvm-1.2/uvm_pkg.sv

//-------------------------------------
// yuu_common/amba dependency packages
//-------------------------------------
${APLC_TB_HOME}/../vip/yuu_ahb/pkg/yuu_common/include/yuu_common_pkg.sv
${APLC_TB_HOME}/../vip/yuu_ahb/pkg/yuu_amba/include/yuu_amba_pkg.sv

//-------------------------------------
// yuu_ahb VIP package
//-------------------------------------
${APLC_TB_HOME}/../vip/yuu_ahb/include/yuu_ahb_pkg.sv

//-------------------------------------
// APLC SPI VIP package
//-------------------------------------
${APLC_TB_HOME}/../vip/spi/aplc_spi_pkg.sv

//-------------------------------------
// APLC TB package
//-------------------------------------
${APLC_TB_HOME}/tb/env/aplc_tb_pkg.sv

//-------------------------------------
// RTL
//-------------------------------------
${APLC_RTL_HOME}/SLC_CSRFILE.sv
${APLC_RTL_HOME}/SLC_CAXIS.sv
${APLC_RTL_HOME}/SLC_SAXIS.sv
${APLC_RTL_HOME}/SLC_DPCHK.sv
${APLC_RTL_HOME}/SLC_CCMD.sv
${APLC_RTL_HOME}/SLC_DPIPE.sv
${APLC_RTL_HOME}/SLC_TPIPE.sv
${APLC_RTL_HOME}/SLC_RXFIFO.sv
${APLC_RTL_HOME}/SLC_TXFIFO.sv
${APLC_RTL_HOME}/SLC_SCTRL_FRONT.sv
${APLC_RTL_HOME}/SLC_SCTRL_BACK.sv
${APLC_RTL_HOME}/SLC_SAXIM.sv
${APLC_RTL_HOME}/SLC_WBB.sv
${APLC_RTL_HOME}/SLC_BANK.sv
${APLC_RTL_HOME}/SLC_TASKALLO.sv
${APLC_RTL_HOME}/APLC_LITE.sv

//-------------------------------------
// TB Top
//-------------------------------------
${APLC_TB_HOME}/tb/if/aplc_csr_if.sv
${APLC_TB_HOME}/tb/tb_top.sv
