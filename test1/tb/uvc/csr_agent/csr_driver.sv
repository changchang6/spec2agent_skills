`ifndef CSR_DRIVER_SV
`define CSR_DRIVER_SV

class csr_driver extends uvm_driver #(csr_transaction);

    virtual csr_if vif;

    uvm_analysis_port #(csr_transaction) ap_port;

    `uvm_component_utils(csr_driver)

    function new(string name, uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual csr_if)::get(this, "", "csr_vif", vif))
            `uvm_fatal("NOVIF", "Virtual interface not set")
        ap_port = new("ap_port", this);
    endfunction

    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        this.get_and_drive();
    endtask

    virtual task get_and_drive();
        wait(vif.rst_n === 1'b1);
        // Initialize rdata to 0
        vif.drv_cb.csr_rdata <= 32'h0;
        forever begin
            csr_transaction trans;
            seq_item_port.get_next_item(req);
            if(!$cast(trans, req.clone()))
                `uvm_fatal(get_type_name(), "csr_driver get trans failed!")
            trans_drive(trans);
            ap_port.write(trans);
            seq_item_port.item_done();
        end
    endtask : get_and_drive

    virtual task trans_drive(csr_transaction tr);
        // CSR agent acts as CSR File (slave) responding to DUT
        // Wait for DUT to initiate CSR access
        if(tr.is_write) begin
            // Wait for write enable from DUT
            wait(vif.csr_wr_en === 1'b1);
            @(vif.mon_cb);
            // Capture write data from DUT
            tr.addr  = vif.mon_cb.csr_addr;
            tr.wdata = vif.mon_cb.csr_wdata;
        end else begin
            // Wait for read enable from DUT
            wait(vif.csr_rd_en === 1'b1);
            // Capture address
            tr.addr = vif.mon_cb.csr_addr;
            @(vif.drv_cb);
            // Drive read data on next cycle (1-cycle read latency per LRS §4.6.2)
            vif.drv_cb.csr_rdata <= tr.rdata;
        end
    endtask

endclass : csr_driver

`endif
