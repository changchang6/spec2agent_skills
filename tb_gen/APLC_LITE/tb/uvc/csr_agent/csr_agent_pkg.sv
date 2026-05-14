`ifndef CSR_AGENT_PKG_SV
`define CSR_AGENT_PKG_SV

package csr_agent_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    `include "csr_defines.sv"
    `include "csr_transaction.sv"
    `include "csr_agent_cfg.sv"
    `include "csr_monitor.sv"
    `include "csr_agent.sv"

endpackage : csr_agent_pkg

`endif
