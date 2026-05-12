// APLC Smoke Test
// Performs basic CSR write-read and AHB write-read operations

`ifndef APLC_SMOKE_TEST_SV
`define APLC_SMOKE_TEST_SV

class aplc_smoke_test extends aplc_base_test;

    `uvm_component_utils(aplc_smoke_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        aplc_smoke_seq seq;

        phase.raise_objection(this, "Starting smoke test");

        seq = aplc_smoke_seq::type_id::create("seq");
        seq.start(m_env.m_spi_agent.m_sequencer);

        // Wait for some cycles after sequence completes
        #1us;

        phase.drop_objection(this, "Smoke test completed");
    endtask

endclass

`endif
