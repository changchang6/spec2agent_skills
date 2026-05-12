`ifndef APLC_ENV_CONFIG_SV
`define APLC_ENV_CONFIG_SV

class aplc_env_config extends uvm_object;

    `uvm_object_utils(aplc_env_config)

    aplc_spi_agent_config  spi_cfg;
    yuu_ahb_env_config     ahb_env_cfg;

    function new(string name = "aplc_env_config");
        super.new(name);
        spi_cfg = aplc_spi_agent_config::type_id::create("spi_cfg");
        ahb_env_cfg = yuu_ahb_env_config::type_id::create("ahb_env_cfg");
    endfunction

endclass

`endif
