`ifndef APLC_SPI_AGENT_SV
`define APLC_SPI_AGENT_SV

class aplc_spi_agent extends uvm_agent;
    `uvm_component_utils(aplc_spi_agent)

    aplc_spi_agent_config m_cfg;
    aplc_spi_driver       m_driver;
    aplc_spi_monitor      m_monitor;
    aplc_spi_sequencer    m_sequencer;
    aplc_spi_coverage     m_coverage;

    uvm_analysis_port #(aplc_spi_mon_item) req_ap;
    uvm_analysis_port #(aplc_spi_mon_item) rsp_ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(aplc_spi_agent_config)::get(this, "", "cfg", m_cfg))
            `uvm_fatal("SPI_AGENT", "Failed to get agent config")

        if (m_cfg.m_vif == null)
            if (!uvm_config_db #(virtual aplc_spi_if)::get(this, "", "m_vif", m_cfg.m_vif))
                `uvm_fatal("SPI_AGENT", "Failed to get virtual interface")

        m_monitor = aplc_spi_monitor::type_id::create("m_monitor", this);

        if (m_cfg.is_active == UVM_ACTIVE) begin
            m_driver    = aplc_spi_driver::type_id::create("m_driver", this);
            m_sequencer = aplc_spi_sequencer::type_id::create("m_sequencer", this);
        end

        m_coverage = aplc_spi_coverage::type_id::create("m_coverage", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        req_ap = m_monitor.req_ap;
        rsp_ap = m_monitor.rsp_ap;

        m_monitor.m_cfg = m_cfg;

        if (m_cfg.is_active == UVM_ACTIVE) begin
            m_driver.m_cfg = m_cfg;
            m_driver.seq_item_port.connect(m_sequencer.seq_item_export);
        end

        m_monitor.rsp_ap.connect(m_coverage.analysis_export);
    endfunction
endclass

`endif
