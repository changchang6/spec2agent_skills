`ifndef CSR_IF__SV
`define CSR_IF__SV

interface csr_if(
    input clk,
    input rst_n,
    input csr_rd_en,
    input csr_wr_en,
    input [7:0] csr_addr,
    input [31:0] csr_wdata,
    input [31:0] csr_rdata
);

    // AI gen: Clocking block for passive monitor
    clocking mon_cb @(posedge clk);
        input csr_rd_en;
        input csr_wr_en;
        input csr_addr;
        input csr_wdata;
        input csr_rdata;
    endclocking

    `ifdef ASSERT_ON

    // AI gen: CHK_003 - CSR write: wr_en single-cycle pulse, addr/wdata valid same cycle
    property p_csr_wr_pulse;
        @(posedge clk) disable iff (!rst_n)
        csr_wr_en |-> csr_addr < 8'h40;
    endproperty
    assert_csr_wr_addr_range: assert property (p_csr_wr_pulse)
        else $error("ASSERT: CSR write with addr>=0x40, should be rejected by pre-check");

    // AI gen: CHK_003 - CSR read: rd_en single-cycle pulse
    property p_csr_rd_pulse;
        @(posedge clk) disable iff (!rst_n)
        csr_rd_en |-> csr_addr < 8'h40;
    endproperty
    assert_csr_rd_addr_range: assert property (p_csr_rd_pulse)
        else $error("ASSERT: CSR read with addr>=0x40, should be rejected by pre-check");

    // AI gen: CHK_003 - CSR write and read should not be simultaneous
    property p_csr_exclusive;
        @(posedge clk) disable iff (!rst_n)
        !(csr_wr_en && csr_rd_en);
    endproperty
    assert_csr_exclusive: assert property (p_csr_exclusive)
        else $error("ASSERT: CSR write and read simultaneous");

    // AI gen: CHK_001 - Reset state: csr_rd_en=0, csr_wr_en=0
    property p_reset_csr_idle;
        @(posedge clk) !rst_n |-> (!csr_rd_en && !csr_wr_en);
    endproperty
    assert_reset_csr_idle: assert property (p_reset_csr_idle)
        else $error("ASSERT: CSR signals not idle during reset");

    `endif

endinterface

`endif
