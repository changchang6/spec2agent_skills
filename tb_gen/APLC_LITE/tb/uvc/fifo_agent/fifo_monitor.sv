`ifndef FIFO_MONITOR_SV
`define FIFO_MONITOR_SV

class fifo_monitor extends uvm_monitor;
    virtual fifo_if vif;
    uvm_analysis_port #(fifo_transaction) ap_port;

    // AI gen: Track previous state for transition detection
    bit prev_rxfifo_empty;
    bit prev_rxfifo_full;
    bit prev_txfifo_empty;
    bit prev_txfifo_full;

    `uvm_component_utils(fifo_monitor)

    function new(string name = "fifo_monitor", uvm_component parent);
        super.new(name, parent);
        ap_port = new("ap_port", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual fifo_if)::get(this, "", "fifo_vif", vif))
            `uvm_fatal("NOVIF", "Virtual interface not set")
    endfunction

    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        // Initialize previous state
        prev_rxfifo_empty = vif.rxfifo_empty;
        prev_rxfifo_full  = vif.rxfifo_full;
        prev_txfifo_empty = vif.txfifo_empty;
        prev_txfifo_full  = vif.txfifo_full;

        forever begin
            fifo_transaction tr;
            tr = fifo_transaction::type_id::create("tr");
            monitor_fifo(tr);
            print_transaction(tr);
            ap_port.write(tr);
        end
    endtask

    // AI gen: Monitor FIFO status transitions per LRS v2.2 §3.5
    virtual task monitor_fifo(ref fifo_transaction tr);
        @(vif.mon_cb);

        tr.rxfifo_empty = vif.mon_cb.rxfifo_empty;
        tr.rxfifo_full  = vif.mon_cb.rxfifo_full;
        tr.txfifo_empty = vif.mon_cb.txfifo_empty;
        tr.txfifo_full  = vif.mon_cb.txfifo_full;

        // AI gen: Detect transitions and set event type
        if (!prev_rxfifo_full && tr.rxfifo_full) begin
            tr.event_type = fifo_transaction::FIFO_STS_RX_FULL;
        end
        else if (prev_rxfifo_full && !tr.rxfifo_full) begin
            tr.event_type = fifo_transaction::FIFO_STS_RX_NOT_FULL;
        end
        else if (!prev_txfifo_empty && tr.txfifo_empty) begin
            tr.event_type = fifo_transaction::FIFO_STS_TX_EMPTY;
        end
        else if (prev_txfifo_empty && !tr.txfifo_empty) begin
            tr.event_type = fifo_transaction::FIFO_STS_TX_NOT_EMPTY;
        end
        else begin
            tr.event_type = fifo_transaction::FIFO_STS_IDLE;
        end

        // Update previous state
        prev_rxfifo_empty = tr.rxfifo_empty;
        prev_rxfifo_full  = tr.rxfifo_full;
        prev_txfifo_empty = tr.txfifo_empty;
        prev_txfifo_full  = tr.txfifo_full;
    endtask

    // AI gen: Print transaction at UVM_LOW for default visibility
    virtual function void print_transaction(fifo_transaction tr);
        if (tr.event_type != fifo_transaction::FIFO_STS_IDLE) begin
            `uvm_info(get_type_name(), $sformatf("Monitored: %s", tr.convert2string()), UVM_LOW)
        end
    endfunction

endclass : fifo_monitor

`endif
