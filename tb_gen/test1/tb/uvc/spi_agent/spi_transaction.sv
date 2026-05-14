`ifndef SPI_TRANSACTION_SV
`define SPI_TRANSACTION_SV

class spi_transaction extends uvm_sequence_item;

    `uvm_object_utils_begin(spi_transaction)
		//TODO
    `uvm_object_utils_end

    function new(string name = "spi_transaction");
        super.new(name);
    endfunction

endclass : spi_transaction

`endif 