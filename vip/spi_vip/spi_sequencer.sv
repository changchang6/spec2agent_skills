/******************************************************************************
 * SPI VIP Sequencer
 * Description: Sequencer for SPI VIP
 ******************************************************************************/

`ifndef SPI_SEQUENCER_SV
`define SPI_SEQUENCER_SV

class spi_sequencer extends uvm_sequencer#(spi_item);

    `uvm_component_utils(spi_sequencer)

    function new(string name = "spi_sequencer", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void handle_reset(uvm_phase phase);
        int objections_count;
        stop_sequences();

        objections_count = uvm_test_done.get_objection_count(this);

        if(objections_count > 0) begin
            uvm_test_done.drop_objection(this,
                $sformatf("Dropping %0d objections at reset", objections_count),
                objections_count);
        end

        start_phase_sequence(phase);
    endfunction

endclass

`endif
