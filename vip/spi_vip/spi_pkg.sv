`ifndef SPI_PKG_SV
`define SPI_PKG_SV

`include "spi_if.sv"

package spi_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  `include "spi_types.sv"
  `include "spi_item.sv"
  `include "spi_mon_item.sv"
  `include "spi_drv_item.sv"
  `include "spi_agent_config.sv"
  `include "spi_coverage.sv"
  `include "spi_monitor.sv"
  `include "spi_driver.sv"
  `include "spi_sequencer.sv"
  `include "spi_agent.sv"
  `include "spi_seq_lib.sv"

endpackage : spi_pkg

`endif // SPI_PKG_SV
