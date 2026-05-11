`ifndef SPI_AGENT_CONFIG_SV
`define SPI_AGENT_CONFIG_SV

class spi_agent_config extends uvm_component;

  `uvm_component_utils(spi_agent_config)

  protected uvm_active_passive_enum m_is_active = UVM_ACTIVE;
  protected bit m_has_coverage = 1;
  protected bit m_has_checks  = 1;
  protected spi_vif_t m_vif;

  // DUT control signal defaults
  protected logic m_en        = 1'b1;
  protected logic m_test_mode = 1'b1;

  // Default lane mode
  protected spi_lane_mode_t m_lane_mode = SPI_LANE_16BIT;

  // Inter-transaction driving delay
  protected int unsigned m_driving_delay = 0;

  function new(string name = "spi_agent_config", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  // Getters and setters
  function void set_is_active(uvm_active_passive_enum val);
    m_is_active = val;
  endfunction

  function uvm_active_passive_enum get_is_active();
    return m_is_active;
  endfunction

  function void set_has_coverage(bit val);
    m_has_coverage = val;
  endfunction

  function bit get_has_coverage();
    return m_has_coverage;
  endfunction

  function void set_has_checks(bit val);
    m_has_checks = val;
  endfunction

  function bit get_has_checks();
    return m_has_checks;
  endfunction

  function void set_vif(spi_vif_t vif);
    m_vif = vif;
  endfunction

  function spi_vif_t get_vif();
    return m_vif;
  endfunction

  function void set_en(logic val);
    m_en = val;
    if (m_vif != null) m_vif.en = val;
  endfunction

  function logic get_en();
    return m_en;
  endfunction

  function void set_test_mode(logic val);
    m_test_mode = val;
    if (m_vif != null) m_vif.test_mode = val;
  endfunction

  function logic get_test_mode();
    return m_test_mode;
  endfunction

  function void set_lane_mode(spi_lane_mode_t val);
    m_lane_mode = val;
    if (m_vif != null) m_vif.lane_mode = val;
  endfunction

  function spi_lane_mode_t get_lane_mode();
    return m_lane_mode;
  endfunction

  function void set_driving_delay(int unsigned val);
    m_driving_delay = val;
  endfunction

  function int unsigned get_driving_delay();
    return m_driving_delay;
  endfunction

  virtual function string get_id();
    return "SPI_AGT_CFG";
  endfunction

  virtual task wait_reset_start();
    @(negedge m_vif.rst_n);
  endtask

  virtual task wait_reset_end();
    wait(m_vif.rst_n === 1'b1);
  endtask

  virtual function void start_of_simulation_phase(uvm_phase phase);
    super.start_of_simulation_phase(phase);
    if (m_vif == null) begin
      `uvm_fatal(get_id(), "Virtual interface is not set!")
    end
    m_vif.en        = m_en;
    m_vif.test_mode = m_test_mode;
    m_vif.lane_mode = m_lane_mode;
  endfunction

endclass : spi_agent_config

`endif // SPI_AGENT_CONFIG_SV
