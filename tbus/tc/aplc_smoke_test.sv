`ifndef APLC_SMOKE_TEST_SV
`define APLC_SMOKE_TEST_SV

class aplc_smoke_test extends aplc_base_test;
    `uvm_component_utils(aplc_smoke_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        aplc_smoke_seq seq;
        seq = aplc_smoke_seq::type_id::create("seq");
        seq.starting_phase = phase;
        seq.start(m_env.m_spi_agent.m_sequencer);
    endtask
endclass

`endif
