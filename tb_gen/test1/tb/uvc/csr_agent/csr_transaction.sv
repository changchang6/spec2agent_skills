`ifndef CSR_TRANSACTION_SV
`define CSR_TRANSACTION_SV

class csr_transaction extends uvm_sequence_item;

    `uvm_object_utils_begin(csr_transaction)
		//TODO
    `uvm_object_utils_end

    function new(string name = "csr_transaction");
        super.new(name);
    endfunction

endclass : csr_transaction

`endif 