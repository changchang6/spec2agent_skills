// APLC CSR Interface
// Models the external CSR file interface for APLC-Lite

`ifndef APLC_CSR_IF_SV
`define APLC_CSR_IF_SV

interface aplc_csr_if (
    input  logic        clk,
    input  logic        rst_n
);

    logic        csr_rd_en;
    logic        csr_wr_en;
    logic [7:0]  csr_addr;
    logic [31:0] csr_wdata;
    logic [31:0] csr_rdata;

    clocking mon_cb @(posedge clk);
        default input #1step output #1step;
        input csr_rd_en, csr_wr_en, csr_addr, csr_wdata, csr_rdata;
    endclocking

    modport mon_mp (
        clocking mon_cb,
        input rst_n
    );

endinterface

`endif
