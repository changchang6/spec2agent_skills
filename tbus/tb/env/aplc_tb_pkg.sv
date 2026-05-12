`ifndef APLC_TB_PKG_SV
`define APLC_TB_PKG_SV

package aplc_tb_pkg;

    `include "uvm_macros.svh"
    import uvm_pkg::*;
    import aplc_spi_pkg::*;
    import yuu_ahb_pkg::*;
    import yuu_common_pkg::*;
    import yuu_amba_pkg::*;

    `include "aplc_env_config.sv"
    `include "aplc_env.sv"
    `include "aplc_smoke_seq.sv"
    `include "aplc_base_test.sv"
    `include "aplc_smoke_test.sv"

endpackage

`endif
