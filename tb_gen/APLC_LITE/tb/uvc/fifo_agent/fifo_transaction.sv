`ifndef FIFO_TRANSACTION_SV
`define FIFO_TRANSACTION_SV

class fifo_transaction extends uvm_sequence_item;

    // AI gen: FIFO status transaction fields per LRS v2.2 §3.5
    rand bit rxfifo_empty;
    rand bit rxfifo_full;
    rand bit txfifo_empty;
    rand bit txfifo_full;

    // AI gen: Event type for tracking transitions
    typedef enum {
        FIFO_STS_IDLE,
        FIFO_STS_RX_FULL,
        FIFO_STS_RX_NOT_FULL,
        FIFO_STS_TX_EMPTY,
        FIFO_STS_TX_NOT_EMPTY
    } fifo_event_e;
    rand fifo_event_e event_type;

    `uvm_object_utils_begin(fifo_transaction)
        `uvm_field_int(rxfifo_empty, UVM_ALL_ON)
        `uvm_field_int(rxfifo_full,  UVM_ALL_ON)
        `uvm_field_int(txfifo_empty, UVM_ALL_ON)
        `uvm_field_int(txfifo_full,  UVM_ALL_ON)
        `uvm_field_enum(fifo_event_e, event_type, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "fifo_transaction");
        super.new(name);
    endfunction

    // AI gen: Convert2string for debug
    virtual function string convert2string();
        return $sformatf("rx_empty=%0b rx_full=%0b tx_empty=%0b tx_full=%0b [%s]",
                         rxfifo_empty, rxfifo_full, txfifo_empty, txfifo_full, event_type.name());
    endfunction

endclass : fifo_transaction

`endif
