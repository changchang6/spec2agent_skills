`ifndef SPI_IF__SV
`define SPI_IF__SV

interface spi_if(
	    input clk,
     input rst_n,
     input en,
     input test_mode,
     input pcs_n,
     input pdi,
     input pdo,
     input pdo_oe,
     input lane_mode
);
   
   `ifdef ASSERT_ON
   //you can add assert case here
   `endif
endinterface

`endif
