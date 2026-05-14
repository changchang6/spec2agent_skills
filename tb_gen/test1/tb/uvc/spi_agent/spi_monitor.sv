`ifndef SPI_MONITOR_SV
`define SPI_MONITOR_SV

class spi_monitor extends uvm_monitor;
	virtual spi_if vif;
    uvm_analysis_port #(spi_transaction) ap_port;

	`uvm_component_utils(spi_monitor)
	
    function new(string name = "spi_monitor", uvm_component parent);
        super.new(name, parent);
        ap_port = new("ap_port", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual spi_if)::get(this, "", "spi_vif", vif))
            `uvm_fatal("NOVIF", "Virtual interface not set")
    endfunction

    task main_phase(uvm_phase phase);
		spi_transaction tr;
		super.main_phase(phase);
        //while(1) begin
        //    tr = new("tr");
        //    demo_monitor_data(tr);
        //    ap.write(tr);
        //end
    endtask

    task demo_monitor_data(ref spi_transaction tr);
		//TODO
    endtask

endclass : spi_monitor

`endif 
