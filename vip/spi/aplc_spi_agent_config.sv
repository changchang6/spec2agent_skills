`ifndef APLC_SPI_AGENT_CONFIG_SV
`define APLC_SPI_AGENT_CONFIG_SV

class aplc_spi_agent_config extends uvm_object;

    `uvm_object_utils(aplc_spi_agent_config)

    uvm_active_passive_enum is_active = UVM_ACTIVE;
    bit                     has_coverage = 1'b1;
    bit                     has_checks   = 1'b1;

    protected aplc_spi_vif_t m_vif;

    function new(string name = "aplc_spi_agent_config");
        super.new(name);
    endfunction

    virtual function void set_vif(aplc_spi_vif_t vif);
        m_vif = vif;
    endfunction

    virtual function aplc_spi_vif_t get_vif();
        return m_vif;
    endfunction

    virtual function void start_of_simulation();
        if (m_vif != null) begin
            m_vif.en_checks = has_checks;
        end
    endfunction

endclass

`endif
