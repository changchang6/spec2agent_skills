`ifndef CSR_MONITOR_SV
`define CSR_MONITOR_SV

class csr_monitor extends uvm_monitor;
	virtual spi_if vif;
    uvm_analysis_port #(csr_transaction) ap_port;

	`uvm_component_utils(csr_monitor)
	
    function new(string name = "csr_monitor", uvm_component parent);
        super.new(name, parent);
        ap_port = new("ap_port", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual spi_if)::get(this, "", "spi_vif", vif))
            `uvm_fatal("NOVIF", "Virtual interface not set")
    endfunction

    task main_phase(uvm_phase phase);
		csr_transaction tr;
		super.main_phase(phase);
        //while(1) begin
        //    tr = new("tr");
        //    demo_monitor_data(tr);
        //    ap.write(tr);
        //end
    endtask

    task demo_monitor_data(ref csr_transaction tr);
		//TODO
    endtask

endclass : csr_monitor

`endif 
