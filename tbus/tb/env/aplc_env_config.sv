// APLC TB Environment Configuration
`ifndef APLC_ENV_CONFIG_SV
`define APLC_ENV_CONFIG_SV

class aplc_env_config extends uvm_object;

    // SPI agent config
    aplc_spi_agent_config m_spi_cfg;

    // AHB slave agent is passive in this TB (handled by yuu_ahb)
    bit m_has_ahb_slave = 1'b1;

    // CSR agent is passive (driven by interface logic)
    bit m_has_csr_agent = 1'b0;

    `uvm_object_utils(aplc_env_config)

    function new(string name = "aplc_env_config");
        super.new(name);
        m_spi_cfg = aplc_spi_agent_config::type_id::create("m_spi_cfg");
    endfunction

endclass

`endif
