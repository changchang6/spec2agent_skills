`ifndef SPI_SEQUENCER_SV
`define SPI_SEQUENCER_SV

class spi_sequencer extends uvm_sequencer#(spi_drv_item);

  `uvm_component_utils(spi_sequencer)

  spi_agent_config m_agent_config;

  function new(string name = "spi_sequencer", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void handle_reset(uvm_phase phase);
    stop_sequences();
    start_phase_sequence(phase);
  endfunction

endclass : spi_sequencer

`endif // SPI_SEQUENCER_SV
