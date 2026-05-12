`ifndef APLC_ENV_SV
`define APLC_ENV_SV

class aplc_env extends uvm_env;

    `uvm_component_utils(aplc_env)

    aplc_spi_agent  m_spi_agent;
    yuu_ahb_env     m_ahb_env;

    protected aplc_env_config m_config;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(aplc_env_config)::get(this, "", "aplc_env_config", m_config)) begin
            `uvm_fatal(get_id(), "Cannot get env config")
        end

        uvm_config_db #(aplc_spi_agent_config)::set(this, "m_spi_agent",
            "aplc_spi_agent_config", m_config.spi_cfg);
        m_spi_agent = aplc_spi_agent::type_id::create("m_spi_agent", this);

        uvm_config_db #(yuu_ahb_env_config)::set(this, "m_ahb_env",
            "cfg", m_config.ahb_env_cfg);
        m_ahb_env = yuu_ahb_env::type_id::create("m_ahb_env", this);
    endfunction

    protected virtual function string get_id();
        return "ENV";
    endfunction

endclass

`endif
