`ifndef CSR_TRANSACTION_SV
`define CSR_TRANSACTION_SV

class csr_transaction extends uvm_sequence_item;

    // AI gen: CSR transaction fields per DV_SPEC Agent 3
    rand bit [7:0]  addr;
    rand bit [31:0] data;
    rand bit        is_write;
    bit             addr_out_of_range;

    `uvm_object_utils_begin(csr_transaction)
        `uvm_field_int(addr,     UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(data,     UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(is_write, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "csr_transaction");
        super.new(name);
    endfunction

    // AI gen: Convert2string for debug
    virtual function string convert2string();
        string s;
        s = $sformatf("addr=0x%02h data=0x%08h %s",
                       addr, data, is_write ? "WR" : "RD");
        if (addr_out_of_range) s = {s, " [ADDR_OUT_OF_RANGE]"};
        return s;
    endfunction

endclass : csr_transaction

`endif
