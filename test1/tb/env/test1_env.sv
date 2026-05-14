`ifndef TEST1_ENV_SV
`define TEST1_ENV_SV

class test1_env extends uvm_env;
    `uvm_component_utils(test1_env)

	spi_agent_cfg spi_agt_config[SPI_NUM];
    spi_agent spi_agt[SPI_NUM];
    csr_agent_cfg csr_agt_config[CSR_NUM];
    csr_agent csr_agt[CSR_NUM];
	uvm_tlm_analysis_fifo #(spi_transaction) spi_agent2rm_fifo[SPI_NUM];
    uvm_tlm_analysis_fifo #(csr_transaction) csr_agent2rm_fifo[CSR_NUM];

    test1_rm			m_rm;
    test1_scoreboard	m_scb;
	
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
		// Configure and create spi agents
        foreach(spi_agt[i]) begin
            spi_agt_config[i] = spi_agent_cfg::type_id::create($sformatf("spi_agt_config[%0d]", i));
            spi_agt_config[i].enable_monitor = 0;
            uvm_config_db#(spi_agent_cfg)::set(this, $sformatf("spi_agt[%0d]", i), "cfg", spi_agt_config[i]);
            spi_agt[i] = spi_agent::type_id::create($sformatf("spi_agt[%0d]", i), this);
        end
        // Configure and create csr agents
        foreach(csr_agt[i]) begin
            csr_agt_config[i] = csr_agent_cfg::type_id::create($sformatf("csr_agt_config[%0d]", i));
            csr_agt_config[i].enable_monitor = 0;
            uvm_config_db#(csr_agent_cfg)::set(this, $sformatf("csr_agt[%0d]", i), "cfg", csr_agt_config[i]);
            csr_agt[i] = csr_agent::type_id::create($sformatf("csr_agt[%0d]", i), this);
        end
		m_rm = test1_rm::type_id::create("m_rm", this);
		m_scb = test1_scoreboard::type_id::create("m_scb", this);
		foreach(spi_agent2rm_fifo[i]) begin
            spi_agent2rm_fifo[i] = new($sformatf("spi_agent2rm_fifo[%0d]", i), this);
        end
        foreach(csr_agent2rm_fifo[i]) begin
            csr_agent2rm_fifo[i] = new($sformatf("csr_agent2rm_fifo[%0d]", i), this);
        end
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        
		// input agents to rm
        for(int i = 0; i < SPI_NUM; i++) begin
            spi_agt[i].ap_port.connect(spi_agent2rm_fifo[i].analysis_export);
            m_rm.spi_port_in[i].connect(spi_agent2rm_fifo[i].blocking_get_export);
        end
        // input agents to rm
        for(int i = 0; i < CSR_NUM; i++) begin
            csr_agt[i].ap_port.connect(csr_agent2rm_fifo[i].analysis_export);
            m_rm.csr_port_in[i].connect(csr_agent2rm_fifo[i].blocking_get_export);
        end
    endfunction

    function void report_phase(uvm_phase phase);
        `uvm_info("ENV", "Environment report", UVM_LOW)
    endfunction

endclass : test1_env

`endif 