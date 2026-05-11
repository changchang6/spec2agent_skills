`ifndef SPI_AGENT_SV
`define SPI_AGENT_SV

class spi_agent extends uvm_agent;

  `uvm_component_utils(spi_agent)

  spi_agent_config  m_agent_config;
  spi_monitor       m_monitor;
  spi_driver        m_driver;
  spi_sequencer     m_sequencer;
  spi_coverage      m_coverage;

  function new(string name = "spi_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(spi_agent_config)::get(this, "", "spi_agent_config", m_agent_config)) begin
      `uvm_fatal("SPI_AGT", "Failed to get spi_agent_config from config_db")
    end

    m_monitor = spi_monitor::type_id::create("m_monitor", this);

    if (m_agent_config.get_is_active() == UVM_ACTIVE) begin
      m_driver    = spi_driver::type_id::create("m_driver", this);
      m_sequencer = spi_sequencer::type_id::create("m_sequencer", this);
    end

    if (m_agent_config.get_has_coverage())
      m_coverage = spi_coverage::type_id::create("m_coverage", this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    m_monitor.m_agent_config = m_agent_config;

    if (m_agent_config.get_is_active() == UVM_ACTIVE) begin
      m_driver.m_agent_config    = m_agent_config;
      m_sequencer.m_agent_config = m_agent_config;
      m_driver.seq_item_port.connect(m_sequencer.seq_item_export);
    end

    if (m_agent_config.get_has_coverage()) begin
      m_coverage.m_agent_config = m_agent_config;
      m_monitor.output_port.connect(m_coverage.mon_port);
    end
  endfunction

endclass : spi_agent

`endif // SPI_AGENT_SV
