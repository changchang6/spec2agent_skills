/******************************************************************************
 * SPI VIP Agent
 * Description: Agent for SPI VIP
 ******************************************************************************/

`ifndef SPI_AGENT_SV
`define SPI_AGENT_SV

class spi_agent extends uvm_agent;

    `uvm_component_utils(spi_agent)

    spi_agent_config m_config;

    spi_driver m_driver;
    spi_sequencer m_sequencer;
    spi_monitor m_monitor;
    spi_coverage m_coverage;

    function new(string name = "spi_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function string get_id();
        return "SPI_AGT";
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if(!uvm_config_db#(spi_agent_config)::get(this, "", "agent_config", m_config)) begin
            `uvm_fatal(get_id(), "Agent configuration not found in config_db")
        end

        m_monitor = spi_monitor::type_id::create("m_monitor", this);

        if(m_config.get_is_active() == UVM_ACTIVE) begin
            m_driver = spi_driver::type_id::create("m_driver", this);
            m_sequencer = spi_sequencer::type_id::create("m_sequencer", this);
        end

        if(m_config.get_has_coverage()) begin
            m_coverage = spi_coverage::type_id::create("m_coverage", this);
        end
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        m_monitor.m_config = m_config;

        if(m_driver != null) begin
            m_driver.m_config = m_config;
            m_driver.seq_item_port.connect(m_sequencer.seq_item_export);
        end

        if(m_coverage != null) begin
            m_coverage.m_config = m_config;
            m_monitor.analysis_port.connect(m_coverage.analysis_port);
        end
    endfunction

    virtual task wait_reset_start();
        m_config.wait_reset_start();
    endtask

    virtual task wait_reset_end();
        m_config.wait_reset_end();
    endtask

    virtual function void handle_reset(uvm_phase phase);
        m_monitor.handle_reset();

        if(m_driver != null) begin
            m_driver.handle_reset();
        end

        if(m_sequencer != null) begin
            m_sequencer.handle_reset(phase);
        end

        if(m_coverage != null) begin
            m_coverage.handle_reset();
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        forever begin
            wait_reset_start();
            `uvm_info(get_id(), "Reset start detected", UVM_LOW)
            handle_reset(phase);
            wait_reset_end();
            `uvm_info(get_id(), "Reset end detected", UVM_LOW)
        end
    endtask

endclass

`endif
