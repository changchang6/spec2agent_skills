// APLC SPI VIP Agent

`ifndef APLC_SPI_AGENT_SV
`define APLC_SPI_AGENT_SV

class aplc_spi_agent extends uvm_agent;

    `uvm_component_utils(aplc_spi_agent)

    aplc_spi_agent_config m_cfg;

    aplc_spi_driver     m_driver;
    aplc_spi_monitor    m_monitor;
    aplc_spi_sequencer  m_sequencer;
    aplc_spi_coverage   m_coverage;

    uvm_analysis_port #(aplc_spi_mon_item) out_port;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db#(aplc_spi_agent_config)::get(this, "", "agent_config", m_cfg)) begin
            `uvm_fatal("APLC_SPI_AGENT", "Cannot get agent_config")
        end

        // Always create monitor
        m_monitor = aplc_spi_monitor::type_id::create("m_monitor", this);

        // Create active components
        if (m_cfg.is_active == UVM_ACTIVE) begin
            m_driver     = aplc_spi_driver::type_id::create("m_driver", this);
            m_sequencer  = aplc_spi_sequencer::type_id::create("m_sequencer", this);
        end

        // Create coverage collector
        if (m_cfg.has_coverage) begin
            m_coverage = aplc_spi_coverage::type_id::create("m_coverage", this);
        end

        out_port = new("out_port", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        // Connect monitor output to agent output
        m_monitor.out_port.connect(out_port);

        // Connect coverage
        if (m_cfg.has_coverage && m_coverage != null) begin
            m_monitor.out_port.connect(m_coverage.analysis_export);
        end

        // Connect driver and sequencer
        if (m_cfg.is_active == UVM_ACTIVE) begin
            m_driver.seq_item_port.connect(m_sequencer.seq_item_export);
        end
    endfunction

endclass

`endif
