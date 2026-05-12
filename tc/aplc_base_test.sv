// APLC Base Test

`ifndef APLC_BASE_TEST_SV
`define APLC_BASE_TEST_SV

import aplc_spi_pkg::*;
import yuu_common_pkg::*;
import yuu_ahb_pkg::*;

class aplc_base_test extends uvm_test;

    `uvm_component_utils(aplc_base_test)

    aplc_env m_env;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        m_env = aplc_env::type_id::create("m_env", this);
    endfunction

    virtual function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        uvm_top.print_topology();
    endfunction

    virtual task run_phase(uvm_phase phase);
        phase.phase_done.set_propagate_mode(0);
    endtask

endclass

`endif
