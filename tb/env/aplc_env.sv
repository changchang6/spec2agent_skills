`ifndef APLC_ENV_SV
`define APLC_ENV_SV

class aplc_env extends uvm_env;

  `uvm_component_utils(aplc_env)

  aplc_env_config m_env_config;
  spi_agent       m_spi_agent;

  function new(string name = "aplc_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(aplc_env_config)::get(this, "", "aplc_env_config", m_env_config)) begin
      `uvm_fatal("APLC_ENV", "Failed to get env config")
    end

    m_spi_agent = spi_agent::type_id::create("m_spi_agent", this);
    // Propagate SPI agent config
    uvm_config_db#(spi_agent_config)::set(this, "m_spi_agent", "spi_agent_config",
                                           m_env_config.spi_agent_cfg);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

endclass : aplc_env

`endif // APLC_ENV_SV
