`ifndef CSR_AGENT_SV
`define CSR_AGENT_SV

class csr_agent extends uvm_agent;
    `uvm_component_utils(csr_agent)

    csr_monitor    m_monitor;
    csr_agent_cfg  m_config;

	uvm_analysis_port #(csr_transaction) ap_port;
	
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        if(!uvm_config_db#(csr_agent_cfg)::get(this, "", "m_config", m_config)) begin
            `uvm_info("AGENT", "Creating new config", UVM_LOW)
            m_config = csr_agent_cfg::type_id::create("m_config");
        end
        
        m_monitor = csr_monitor::type_id::create("m_monitor", this);
  
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        ap_port = m_monitor.ap_port;
    endfunction

endclass : csr_agent

`endif 
