`ifndef APLC_ENV_SV
`define APLC_ENV_SV

class aplc_env extends uvm_env;
    `uvm_component_utils(aplc_env)

    aplc_env_config    m_cfg;
    aplc_spi_agent     m_spi_agent;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(aplc_env_config)::get(this, "", "cfg", m_cfg))
            `uvm_fatal("ENV", "Failed to get env config")

        uvm_config_db #(aplc_spi_agent_config)::set(this, "m_spi_agent*", "cfg", m_cfg.spi_cfg);
        m_spi_agent = aplc_spi_agent::type_id::create("m_spi_agent", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
    endfunction
endclass

`endif
