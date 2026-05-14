`ifndef SPI_AGENT_CFG_SV
`define SPI_AGENT_CFG_SV

class spi_agent_cfg extends uvm_object;
	bit enable_monitor = 1;
	bit is_active = 1;
	
	`uvm_obejct_utils(spi_agent_cfg)

    function new(string name = "spi_agent_cfg");
        super.new(name);
    endfunction

endclass : spi_agent_cfg

`endif 
