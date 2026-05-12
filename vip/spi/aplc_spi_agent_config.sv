`ifndef APLC_SPI_AGENT_CONFIG_SV
`define APLC_SPI_AGENT_CONFIG_SV

class aplc_spi_agent_config extends uvm_object;
    `uvm_object_utils(aplc_spi_agent_config)

    uvm_active_passive_enum is_active = UVM_ACTIVE;
    aplc_lane_mode_e        lane_mode = APLC_LANE_16BIT;
    virtual aplc_spi_if     m_vif;

    bit en_protocol_checks = 1;
    bit en_x_z_checks      = 1;

    function new(string name = "aplc_spi_agent_config");
        super.new(name);
    endfunction
endclass

`endif
