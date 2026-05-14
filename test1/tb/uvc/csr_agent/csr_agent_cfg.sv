`ifndef CSR_AGENT_CFG_SV
`define CSR_AGENT_CFG_SV

class csr_agent_cfg extends uvm_object;
    bit enable_monitor = 1;
    bit is_active = 1;

    `uvm_object_utils(csr_agent_cfg)

    function new(string name = "csr_agent_cfg");
        super.new(name);
    endfunction

endclass : csr_agent_cfg

`endif
