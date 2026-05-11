`ifndef APLC_ENV_CONFIG_SV
`define APLC_ENV_CONFIG_SV

class aplc_env_config extends uvm_object;

  `uvm_object_utils(aplc_env_config)

  spi_agent_config spi_agent_cfg;

  function new(string name = "aplc_env_config");
    super.new(name);
  endfunction

endclass : aplc_env_config

`endif // APLC_ENV_CONFIG_SV
