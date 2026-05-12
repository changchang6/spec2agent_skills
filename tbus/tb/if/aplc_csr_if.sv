`ifndef APLC_CSR_IF_SV
`define APLC_CSR_IF_SV

interface aplc_csr_if (input clk, input rst_n);
    logic        csr_rd_en;
    logic        csr_wr_en;
    logic [7:0]  csr_addr;
    logic [31:0] csr_wdata;
    logic [31:0] csr_rdata;

    clocking mon_cb @(posedge clk);
        input csr_rd_en, csr_wr_en, csr_addr, csr_wdata, csr_rdata;
    endclocking

    modport dut (output csr_rd_en, csr_wr_en, csr_addr, csr_wdata,
                 input  csr_rdata);
endinterface

`endif
