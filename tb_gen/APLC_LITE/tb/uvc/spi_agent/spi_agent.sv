`ifndef SPI_AGENT_SV
`define SPI_AGENT_SV

class spi_agent extends uvm_agent;
    `uvm_component_utils(spi_agent)

    spi_driver     m_driver;
    spi_monitor    m_monitor;
    spi_sequencer  m_sequencer;
    spi_agent_cfg  m_config;

	uvm_analysis_port #(spi_transaction) ap_port;
	
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        if(!uvm_config_db#(spi_agent_cfg)::get(this, "", "m_config", m_config)) begin
            `uvm_info("AGENT", "Creating new config", UVM_LOW)
            m_config = spi_agent_cfg::type_id::create("m_config");
        end
        
        if(m_config.is_active) begin
			m_driver = spi_driver::type_id::create("m_driver", this);
			m_sequencer = spi_sequencer::type_id::create("m_sequencer", this);
		end
		m_monitor = spi_monitor::type_id::create("m_monitor", this);
        
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        
        if(m_config.is_active)	m_driver.seq_item_port.connect(m_sequencer.seq_item_export);
		if(m_config.enable_monitor) ap_port = m_monitor.ap_port;
		else ap_port = m_driver.ap_port;
    endfunction

endclass : spi_agent

`endif 
