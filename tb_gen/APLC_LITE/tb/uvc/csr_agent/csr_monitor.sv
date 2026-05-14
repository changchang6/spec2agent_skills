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

    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        forever begin
            csr_transaction tr;
            tr = csr_transaction::type_id::create("tr");
            monitor_csr(tr);
            print_transaction(tr);
            ap_port.write(tr);
        end
    endtask

    // AI gen: Monitor CSR read/write transactions per LRS §4.6
    virtual task monitor_csr(ref csr_transaction tr);
        // Wait for CSR write or read enable
        wait(vif.csr_wr_en === 1'b1 || vif.csr_rd_en === 1'b1);

        if (vif.csr_wr_en === 1'b1) begin
            // AI gen: CSR write - single cycle pulse, addr/wdata valid same cycle
            tr.is_write = 1'b1;
            tr.addr     = vif.csr_addr;
            tr.data     = vif.csr_wdata;
        end else begin
            // AI gen: CSR read - single cycle pulse, rdata valid NEXT cycle
            tr.is_write = 1'b0;
            tr.addr     = vif.csr_addr;
            // Wait 1 cycle for rdata (1 cycle read latency per LRS §4.6.2)
            @(vif.mon_cb);
            tr.data = vif.mon_cb.csr_rdata;
        end

        // AI gen: Check address range
        if (tr.addr >= `CSR_ADDR_MAX + 1) begin
            tr.addr_out_of_range = 1'b1;
        end

        // Wait for enable to drop
        @(vif.mon_cb);
    endtask

    // AI gen: Print transaction at UVM_LOW for default visibility
    virtual function void print_transaction(csr_transaction tr);
        `uvm_info(get_type_name(), $sformatf("Monitored: %s", tr.convert2string()), UVM_LOW)
    endfunction

endclass : csr_monitor

`endif
