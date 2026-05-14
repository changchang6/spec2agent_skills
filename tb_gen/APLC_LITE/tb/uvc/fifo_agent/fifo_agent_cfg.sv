`ifndef FIFO_AGENT_CFG_SV
`define FIFO_AGENT_CFG_SV

class fifo_agent_cfg extends uvm_object;
    bit enable_monitor = 1;
    bit is_active = 0;

    `uvm_object_utils(fifo_agent_cfg)

    function new(string name = "fifo_agent_cfg");
        super.new(name);
    endfunction

endclass : fifo_agent_cfg

`endif
