`ifndef CSR_TRANSACTION_SV
`define CSR_TRANSACTION_SV

class csr_transaction extends uvm_sequence_item;

    rand bit                      is_write;
    rand logic [`CSR_ADDR_WIDTH-1:0] addr;
    rand logic [`DATA_WIDTH-1:0]     wdata;
    logic [`DATA_WIDTH-1:0]          rdata;
    bit                             has_error;

    `uvm_object_utils_begin(csr_transaction)
        `uvm_field_int(is_write, UVM_ALL_ON)
        `uvm_field_int(addr, UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(wdata, UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(rdata, UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(has_error, UVM_ALL_ON)
    `uvm_object_utils_end

    constraint c_addr_range {
        addr < 8'h40;
    }

    function new(string name = "csr_transaction");
        super.new(name);
    endfunction

    virtual function string convert2string();
        string s;
        s = $sformatf("addr=0x%02h %s", addr, is_write ? "WR" : "RD");
        if(is_write)
            s = {s, $sformatf(" wdata=0x%08h", wdata)};
        else
            s = {s, $sformatf(" rdata=0x%08h", rdata)};
        if(has_error)
            s = {s, " ERR"};
        return s;
    endfunction

endclass : csr_transaction

`endif
