// APLC TB Environment
`ifndef APLC_ENV_SV
`define APLC_ENV_SV

class aplc_env extends uvm_env;

    aplc_env_config       m_env_cfg;
    aplc_spi_agent        m_spi_agent;

    `uvm_component_utils(aplc_env)

    function new(string name = "aplc_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db#(aplc_env_config)::get(this, "", "m_env_cfg", m_env_cfg)) begin
            `uvm_fatal("APLC_ENV", "Environment config not set")
        end

        // Create SPI agent
        uvm_config_db#(aplc_spi_agent_config)::set(this, "m_spi_agent*", "m_config", m_env_cfg.m_spi_cfg);
        m_spi_agent = aplc_spi_agent::type_id::create("m_spi_agent", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
    endfunction

endclass

`endif
