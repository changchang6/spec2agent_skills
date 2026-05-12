`ifndef APLC_SPI_PKG_SV
`define APLC_SPI_PKG_SV

`include "aplc_spi_if.sv"

package aplc_spi_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    `include "aplc_spi_types.sv"
    `include "aplc_spi_item.sv"
    `include "aplc_spi_mon_item.sv"
    `include "aplc_spi_agent_config.sv"
    `include "aplc_spi_coverage.sv"
    `include "aplc_spi_monitor.sv"
    `include "aplc_spi_sequencer.sv"
    `include "aplc_spi_driver.sv"
    `include "aplc_spi_agent.sv"
    `include "aplc_spi_seq_lib.sv"

endpackage

`endif
