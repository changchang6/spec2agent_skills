// APLC SPI Sequencer
`ifndef APLC_SPI_SEQUENCER_SV
`define APLC_SPI_SEQUENCER_SV

class aplc_spi_sequencer extends uvm_sequencer #(aplc_spi_item);

    `uvm_component_utils(aplc_spi_sequencer)

    function new(string name = "aplc_spi_sequencer", uvm_component parent = null);
        super.new(name, parent);
    endfunction

endclass

`endif
