`ifndef FIFO_AGENT_PKG_SV
`define FIFO_AGENT_PKG_SV

package fifo_agent_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    `include "fifo_defines.sv"
    `include "fifo_transaction.sv"
    `include "fifo_agent_cfg.sv"
    `include "fifo_monitor.sv"
    `include "fifo_agent.sv"

endpackage : fifo_agent_pkg

`endif
