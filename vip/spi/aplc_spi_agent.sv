`ifndef APLC_SPI_AGENT_SV
`define APLC_SPI_AGENT_SV

class aplc_spi_agent extends uvm_agent;

    `uvm_component_utils(aplc_spi_agent)

    aplc_spi_monitor   m_monitor;
    aplc_spi_driver    m_driver;
    aplc_spi_sequencer m_sequencer;
    aplc_spi_coverage  m_coverage;

    protected aplc_spi_agent_config m_config;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(aplc_spi_agent_config)::get(this, "", "aplc_spi_agent_config", m_config)) begin
            `uvm_fatal(get_id(), "Cannot get agent config")
        end

        m_monitor = aplc_spi_monitor::type_id::create("m_monitor", this);

        if (m_config.get_vif() != null) begin
            uvm_config_db #(aplc_spi_agent_config)::set(this, "m_monitor", "aplc_spi_agent_config", m_config);
        end

        if (m_config.is_active == UVM_ACTIVE) begin
            m_driver    = aplc_spi_driver::type_id::create("m_driver", this);
            m_sequencer = aplc_spi_sequencer::type_id::create("m_sequencer", this);
            uvm_config_db #(aplc_spi_agent_config)::set(this, "m_driver", "aplc_spi_agent_config", m_config);
        end

        if (m_config.has_coverage) begin
            m_coverage = aplc_spi_coverage::type_id::create("m_coverage", this);
        end
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        if (m_config.is_active == UVM_ACTIVE) begin
            m_driver.seq_item_port.connect(m_sequencer.seq_item_export);
        end
        if (m_config.has_coverage) begin
            m_monitor.output_port.connect(m_coverage.item_from_mon);
        end
    endfunction

    protected virtual function string get_id();
        return "AGT";
    endfunction

endclass

`endif
