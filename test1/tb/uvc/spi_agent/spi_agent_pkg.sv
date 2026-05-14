`ifndef SPI_AGENT_PKG_SV
`define SPI_AGENT_PKG_SV

package spi_agent_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    `include "spi_defines.sv"
    `include "spi_transaction.sv"
    `include "spi_agent_cfg.sv"
    `include "spi_driver.sv"
    `include "spi_monitor.sv"
    `include "spi_sequencer.sv"
    `include "spi_agent.sv"

endpackage : spi_agent_pkg

`endif
