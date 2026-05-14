`ifndef APLC_LITE_ENV_SV
`define APLC_LITE_ENV_SV

class APLC_LITE_env extends uvm_env;
    `uvm_component_utils(APLC_LITE_env)

	spi_agent_cfg spi_agt_config[SPI_NUM];
    spi_agent spi_agt[SPI_NUM];
    csr_agent_cfg csr_agt_config[CSR_NUM];
    csr_agent csr_agt[CSR_NUM];
    fifo_agent_cfg fifo_agt_config[FIFO_NUM];
    fifo_agent fifo_agt[FIFO_NUM];
	uvm_tlm_analysis_fifo #(spi_transaction) spi_agent2rm_fifo[SPI_NUM];
    uvm_tlm_analysis_fifo #(csr_transaction) csr_rm2scb_fifo[CSR_NUM];
    uvm_tlm_analysis_fifo #(csr_transaction) csr_agent2scb_fifo[CSR_NUM];
    uvm_tlm_analysis_fifo #(fifo_transaction) fifo_rm2scb_fifo[FIFO_NUM];
    uvm_tlm_analysis_fifo #(fifo_transaction) fifo_agent2scb_fifo[FIFO_NUM];

    APLC_LITE_rm			m_rm;
    APLC_LITE_scoreboard	m_scb;
	
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
        // Configure and create fifo agents
        foreach(fifo_agt[i]) begin
            fifo_agt_config[i] = fifo_agent_cfg::type_id::create($sformatf("fifo_agt_config[%0d]", i));
            fifo_agt_config[i].enable_monitor = 0;
            uvm_config_db#(fifo_agent_cfg)::set(this, $sformatf("fifo_agt[%0d]", i), "cfg", fifo_agt_config[i]);
            fifo_agt[i] = fifo_agent::type_id::create($sformatf("fifo_agt[%0d]", i), this);
        end
		m_rm = APLC_LITE_rm::type_id::create("m_rm", this);
		m_scb = APLC_LITE_scoreboard::type_id::create("m_scb", this);
		foreach(spi_agent2rm_fifo[i]) begin
            spi_agent2rm_fifo[i] = new($sformatf("spi_agent2rm_fifo[%0d]", i), this);
        end
        foreach(csr_agent2scb_fifo[i]) begin
            csr_agent2scb_fifo[i] = new($sformatf("csr_agent2scb_fifo[%0d]", i), this);
            csr_rm2scb_fifo[i] = new($sformatf("csr_rm2scb_fifo[%0d]", i), this);
        end
        foreach(fifo_agent2scb_fifo[i]) begin
            fifo_agent2scb_fifo[i] = new($sformatf("fifo_agent2scb_fifo[%0d]", i), this);
            fifo_rm2scb_fifo[i] = new($sformatf("fifo_rm2scb_fifo[%0d]", i), this);
        end
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        
		// input agents to rm
        for(int i = 0; i < SPI_NUM; i++) begin
            spi_agt[i].ap_port.connect(spi_agent2rm_fifo[i].analysis_export);
            m_rm.spi_port_in[i].connect(spi_agent2rm_fifo[i].blocking_get_export);
        end
        // rm to scb
        for(int i = 0; i < CSR_NUM; i++) begin
            m_rm.csr_port_out[i].connect(csr_rm2scb_fifo[i].analysis_export);
            m_scb.csr_exp_port[i].connect(csr_rm2scb_fifo[i].blocking_get_export);
        end
        
        // output agent to scb
        for(int i = 0; i < CSR_NUM; i++) begin
            csr_agt[i].ap_port.connect(csr_agent2scb_fifo[i].analysis_export);
            m_scb.csr_act_port[i].connect(csr_agent2scb_fifo[i].blocking_get_export);
        end
        // rm to scb
        for(int i = 0; i < FIFO_NUM; i++) begin
            m_rm.fifo_port_out[i].connect(fifo_rm2scb_fifo[i].analysis_export);
            m_scb.fifo_exp_port[i].connect(fifo_rm2scb_fifo[i].blocking_get_export);
        end
        
        // output agent to scb
        for(int i = 0; i < FIFO_NUM; i++) begin
            fifo_agt[i].ap_port.connect(fifo_agent2scb_fifo[i].analysis_export);
            m_scb.fifo_act_port[i].connect(fifo_agent2scb_fifo[i].blocking_get_export);
        end
    endfunction

    function void report_phase(uvm_phase phase);
        `uvm_info("ENV", "Environment report", UVM_LOW)
    endfunction

endclass : APLC_LITE_env

`endif 