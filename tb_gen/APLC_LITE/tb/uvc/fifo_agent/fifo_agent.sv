`ifndef FIFO_AGENT_SV
`define FIFO_AGENT_SV

class fifo_agent extends uvm_agent;
    `uvm_component_utils(fifo_agent)

    fifo_monitor    m_monitor;
    fifo_agent_cfg  m_config;

	uvm_analysis_port #(fifo_transaction) ap_port;
	
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        if(!uvm_config_db#(fifo_agent_cfg)::get(this, "", "m_config", m_config)) begin
            `uvm_info("AGENT", "Creating new config", UVM_LOW)
            m_config = fifo_agent_cfg::type_id::create("m_config");
        end
        
        m_monitor = fifo_monitor::type_id::create("m_monitor", this);
  
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        ap_port = m_monitor.ap_port;
    endfunction

endclass : fifo_agent

`endif 
