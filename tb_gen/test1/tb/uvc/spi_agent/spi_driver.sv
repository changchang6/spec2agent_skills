`ifndef SPI_DRIVER_SV
`define SPI_DRIVER_SV

class spi_driver extends uvm_driver #(spi_transaction);
    

    virtual spi_if vif;
	
	uvm_analysis_port #(spi_transaction) ap_port;
	int											  m_FrameCnt;

	`uvm_component_utils(spi_driver)
    function new(string name, uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual spi_if)::get(this, "", "spi_vif", vif))
            `uvm_fatal("NOVIF", "Virtual interface not set")
        
        ap_port = new("ap_port",this);
    endfunction

    task run_phase(uvm_phase phase);
		super.run_phase(phase);
		//this.reset_signals();
		this.get_and_drive();
    endtask

	virtual task get_and_drive();
		spi_transaction trans;
		trans = spi_transaction::type_id::create("trans");
		wait(vif.rst_n == 'b1);
		m_FrameCnt = 0;
		forever begin
			seq_item_port.get_next_item(req);
			if(! $cast(trans, req.clone()))
				`uvm_fatal(get_type_name(), $sformatf("spi_driver get trans failed!"));
			seq_item_port.item_done();
		end
	endtask : get_and_drive
	
	virtual task trans_drive(spi_transaction tr);
	endtask

endclass : spi_driver

`endif
