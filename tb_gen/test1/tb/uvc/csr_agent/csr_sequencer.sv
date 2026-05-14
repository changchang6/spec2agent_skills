`ifndef CSR_SEQUENCER_SV
`define CSR_SEQUENCER_SV

class csr_sequencer extends uvm_sequencer #(csr_transaction);
    `uvm_component_utils(csr_sequencer)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

endclass : csr_sequencer

`endif