`ifndef APLC_BASE_TEST_SV
`define APLC_BASE_TEST_SV

class aplc_base_test extends uvm_test;
    `uvm_component_utils(aplc_base_test)

    aplc_env         m_env;
    aplc_env_config  m_cfg;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        m_cfg = aplc_env_config::type_id::create("m_cfg");
        m_cfg.spi_cfg.is_active = UVM_ACTIVE;
        m_cfg.spi_cfg.lane_mode = APLC_LANE_16BIT;

        uvm_config_db #(aplc_env_config)::set(this, "m_env", "cfg", m_cfg);
        uvm_config_db #(aplc_spi_agent_config)::set(this, "m_env.m_spi_agent*", "cfg", m_cfg.spi_cfg);

        m_env = aplc_env::type_id::create("m_env", this);
    endfunction

    virtual function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        uvm_top.set_report_verbosity_level_hier(UVM_HIGH);
    endfunction

endclass

`endif
