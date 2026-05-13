// APLC SPI Agent
`ifndef APLC_SPI_AGENT_SV
`define APLC_SPI_AGENT_SV

class aplc_spi_agent extends uvm_agent;

    aplc_spi_agent_config m_config;
    aplc_spi_driver       m_driver;
    aplc_spi_monitor      m_monitor;
    aplc_spi_sequencer    m_sequencer;
    aplc_spi_coverage     m_coverage;

    `uvm_component_utils(aplc_spi_agent)

    function new(string name = "aplc_spi_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db#(aplc_spi_agent_config)::get(this, "", "m_config", m_config)) begin
            `uvm_fatal("APLC_SPI_AGENT", "Agent config not set")
        end

        // Always create monitor
        m_monitor = aplc_spi_monitor::type_id::create("m_monitor", this);

        // Create coverage collector
        m_coverage = aplc_spi_coverage::type_id::create("m_coverage", this);

        // Create driver and sequencer in active mode
        if (m_config.m_is_active == UVM_ACTIVE) begin
            m_driver     = aplc_spi_driver::type_id::create("m_driver", this);
            m_sequencer  = aplc_spi_sequencer::type_id::create("m_sequencer", this);
        end
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        // Set virtual interface for all components
        uvm_config_db#(virtual aplc_spi_if)::set(this, "m_monitor", "vif", m_config.m_vif);

        if (m_config.m_is_active == UVM_ACTIVE) begin
            uvm_config_db#(virtual aplc_spi_if)::set(this, "m_driver", "vif", m_config.m_vif);
            m_driver.seq_item_port.connect(m_sequencer.seq_item_export);
        end

        // Connect monitor to coverage
        m_monitor.m_rsp_port.connect(m_coverage.m_mon_imp);
    endfunction

endclass

`endif
