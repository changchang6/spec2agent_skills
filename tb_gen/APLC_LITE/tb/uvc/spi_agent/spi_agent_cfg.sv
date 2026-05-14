`ifndef SPI_AGENT_CFG_SV
`define SPI_AGENT_CFG_SV

class spi_agent_cfg extends uvm_object;
    bit enable_monitor = 1;
    bit is_active = 1;

    // AI gen: Lane mode configuration
    rand bit [1:0] lane_mode = `LANE_MODE_16BIT;

    // AI gen: Control signals
    rand bit en = 1'b1;
    rand bit test_mode = 1'b1;

    `uvm_object_utils(spi_agent_cfg)

    function new(string name = "spi_agent_cfg");
        super.new(name);
    endfunction

endclass : spi_agent_cfg

`endif
