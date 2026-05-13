// APLC Base Test
`ifndef APLC_BASE_TEST_SV
`define APLC_BASE_TEST_SV

class aplc_base_test extends uvm_test;

    aplc_env m_env;

    `uvm_component_utils(aplc_base_test)

    function new(string name = "aplc_base_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        m_env = aplc_env::type_id::create("m_env", this);
    endfunction

    virtual task run_phase(uvm_phase phase);
        phase.phase_done.set_drain_time(this, 100ns);
    endtask

endclass

`endif
