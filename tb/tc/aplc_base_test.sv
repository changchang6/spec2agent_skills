`ifndef APLC_BASE_TEST_SV
`define APLC_BASE_TEST_SV

class aplc_base_test extends uvm_test;

  `uvm_component_utils(aplc_base_test)

  aplc_env        m_env;
  aplc_env_config m_env_config;
  spi_agent_config m_spi_agent_cfg;
  spi_vif_t       m_spi_vif;

  function new(string name = "aplc_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Create configs
    m_spi_agent_cfg = spi_agent_config::type_id::create("m_spi_agent_cfg", this);
    m_env_config = aplc_env_config::type_id::create("m_env_config");

    // Set SPI agent config
    m_spi_agent_cfg.set_is_active(UVM_ACTIVE);
    m_spi_agent_cfg.set_has_coverage(1);
    m_spi_agent_cfg.set_has_checks(1);
    m_spi_agent_cfg.set_en(1'b1);
    m_spi_agent_cfg.set_test_mode(1'b1);
    m_spi_agent_cfg.set_lane_mode(SPI_LANE_16BIT);

    // Get virtual interface from config_db
    if (!uvm_config_db#(spi_vif_t)::get(this, "", "spi_vif", m_spi_vif)) begin
      `uvm_fatal("APLC_TEST", "Failed to get spi_vif from config_db")
    end
    m_spi_agent_cfg.set_vif(m_spi_vif);

    m_env_config.spi_agent_cfg = m_spi_agent_cfg;
    uvm_config_db#(aplc_env_config)::set(this, "*", "aplc_env_config", m_env_config);

    m_env = aplc_env::type_id::create("m_env", this);
  endfunction

  virtual function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    uvm_top.print_topology();
  endfunction

  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);
  endtask

endclass : aplc_base_test

`endif // APLC_BASE_TEST_SV
