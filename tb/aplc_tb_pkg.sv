`ifndef APLC_TB_PKG_SV
`define APLC_TB_PKG_SV

package aplc_tb_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import spi_pkg::*;

  `include "aplc_env_config.sv"
  `include "aplc_env.sv"
  `include "aplc_base_test.sv"
  `include "aplc_smoke_test.sv"

endpackage : aplc_tb_pkg

`endif // APLC_TB_PKG_SV
