`ifndef CSR_MONITOR_SV
`define CSR_MONITOR_SV

class csr_monitor extends uvm_monitor;
    virtual csr_if vif;
    uvm_analysis_port #(csr_transaction) ap_port;

    `uvm_component_utils(csr_monitor)

    function new(string name = "csr_monitor", uvm_component parent);
        super.new(name, parent);
        ap_port = new("ap_port", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual csr_if)::get(this, "", "csr_vif", vif))
            `uvm_fatal("NOVIF", "Virtual interface not set")
    endfunction

    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        wait(vif.rst_n === 1'b1);
        forever begin
            csr_transaction tr;
            tr = csr_transaction::type_id::create("tr");
            collect_transaction(tr);
            print_transaction(tr);
            ap_port.write(tr);
        end
    endtask

    virtual task collect_transaction(csr_transaction tr);
        // Wait for CSR access (read or write enable)
        wait(vif.csr_rd_en === 1'b1 || vif.csr_wr_en === 1'b1);

        tr.addr = vif.mon_cb.csr_addr;

        if(vif.csr_wr_en === 1'b1) begin
            tr.is_write = 1'b1;
            tr.wdata    = vif.mon_cb.csr_wdata;
        end else begin
            tr.is_write = 1'b0;
            // Read data appears next cycle per LRS §4.6.2
            @(vif.mon_cb);
            tr.rdata = vif.mon_cb.csr_rdata;
        end

        // Check address range violation
        if(tr.addr >= 8'h40) begin
            tr.has_error = 1'b1;
        end

        // Wait for enable to deassert
        wait(vif.csr_rd_en === 1'b0 && vif.csr_wr_en === 1'b0);
        @(vif.mon_cb);
    endtask

    virtual function void print_transaction(csr_transaction tr);
        `uvm_info("CSR_MON", $sformatf("[CSR_MON] %s addr=0x%02h %s%s",
            tr.is_write ? "WR" : "RD",
            tr.addr,
            tr.is_write ? $sformatf("wdata=0x%08h", tr.wdata) :
                          $sformatf("rdata=0x%08h", tr.rdata),
            tr.has_error ? " ADDR_ERR" : ""),
            UVM_LOW)
    endfunction

endclass : csr_monitor

`endif
