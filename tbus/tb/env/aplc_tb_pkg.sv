`ifndef APLC_TB_PKG_SV
`define APLC_TB_PKG_SV

package aplc_tb_pkg;

    import uvm_pkg::*;
    import aplc_spi_pkg::*;
    `include "uvm_macros.svh"

    `include "aplc_env_config.sv"
    `include "aplc_env.sv"
    `include "aplc_base_test.sv"
    `include "aplc_smoke_test.sv"

endpackage

`endif
