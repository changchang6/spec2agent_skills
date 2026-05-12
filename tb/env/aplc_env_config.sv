// APLC Testbench Environment Configuration

`ifndef APLC_ENV_CONFIG_SV
`define APLC_ENV_CONFIG_SV

import aplc_spi_pkg::*;
import yuu_common_pkg::*;
import yuu_ahb_pkg::*;

class aplc_env_config extends uvm_object;

    `uvm_object_utils_begin(aplc_env_config)
        `uvm_field_int(has_spi_agent,   UVM_DEFAULT)
        `uvm_field_int(has_ahb_agent,   UVM_DEFAULT)
        `uvm_field_int(has_csr_file,    UVM_DEFAULT)
        `uvm_field_int(has_scoreboard,  UVM_DEFAULT)
    `uvm_object_utils_end

    bit has_spi_agent  = 1;
    bit has_ahb_agent  = 1;
    bit has_csr_file   = 1;
    bit has_scoreboard = 1;

    aplc_spi_agent_config spi_cfg;
    yuu_ahb_slave_config  ahb_cfg;
    virtual aplc_csr_if   csr_vif;

    function new(string name = "aplc_env_config");
        super.new(name);
    endfunction

endclass

`endif
