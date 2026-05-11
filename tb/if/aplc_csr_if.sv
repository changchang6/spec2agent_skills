`ifndef APLC_CSR_IF_SV
`define APLC_CSR_IF_SV

interface aplc_csr_if(input clk);

  logic        csr_rd_en;
  logic        csr_wr_en;
  logic [7:0]  csr_addr;
  logic [31:0] csr_wdata;
  logic [31:0] csr_rdata;

  clocking slave_cb @(posedge clk);
    input   csr_rd_en, csr_wr_en, csr_addr, csr_wdata;
    output  csr_rdata;
  endclocking

  modport slave(clocking slave_cb);

endinterface : aplc_csr_if

`endif // APLC_CSR_IF_SV
