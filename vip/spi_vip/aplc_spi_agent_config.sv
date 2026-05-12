// APLC SPI VIP Agent Configuration

`ifndef APLC_SPI_AGENT_CONFIG_SV
`define APLC_SPI_AGENT_CONFIG_SV

class aplc_spi_agent_config extends uvm_object;

    `uvm_object_utils_begin(aplc_spi_agent_config)
        `uvm_field_int(is_active,           UVM_DEFAULT)
        `uvm_field_int(has_coverage,        UVM_DEFAULT)
        `uvm_field_int(has_checks,          UVM_DEFAULT)
        `uvm_field_enum(aplc_lane_mode_e, default_lane_mode, UVM_DEFAULT)
        `uvm_field_int(default_en,          UVM_DEFAULT)
        `uvm_field_int(default_test_mode,   UVM_DEFAULT)
    `uvm_object_utils_end

    uvm_active_passive_enum is_active = UVM_ACTIVE;

    bit has_coverage = 1;
    bit has_checks   = 1;

    // Default configuration values driven by the agent
    aplc_lane_mode_e default_lane_mode = APLC_LANE_16BIT;
    bit              default_en        = 1'b1;
    bit              default_test_mode = 1'b1;

    // Virtual interface
    virtual aplc_spi_if m_vif;

    function new(string name = "aplc_spi_agent_config");
        super.new(name);
    endfunction

    virtual function void set_vif(virtual aplc_spi_if vif);
        m_vif = vif;
    endfunction

    virtual function virtual aplc_spi_if get_vif();
        return m_vif;
    endfunction

endclass

`endif
