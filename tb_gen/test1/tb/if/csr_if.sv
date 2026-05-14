`ifndef CSR_IF__SV
`define CSR_IF__SV

interface csr_if(
	    input csr_rd_en,
     input csr_wr_en,
     input csr_addr,
     input csr_wdata,
     input csr_rdata
);
   
   `ifdef ASSERT_ON
   //you can add assert case here
   `endif
endinterface

`endif
