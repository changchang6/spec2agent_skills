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

    // Clocking blocks
    clocking drv_cb @(posedge clk);
        input  csr_rd_en;
        input  csr_wr_en;
        input  csr_addr;
        input  csr_wdata;
        output csr_rdata;
    endclocking

    clocking mon_cb @(posedge clk);
        input csr_rd_en;
        input csr_wr_en;
        input csr_addr;
        input csr_wdata;
        input csr_rdata;
    endclocking

    `ifdef ASSERT_ON

    // CHK_003: CSR write is single-cycle pulse
    property p_wr_single_cycle;
        @(posedge clk) disable iff (!rst_n)
            csr_wr_en |-> ##1 (csr_wr_en == 1'b0);
    endproperty
    assert property(p_wr_single_cycle) else
        $error("CSR_IF ASSERT: csr_wr_en not single-cycle pulse");

    // CHK_003: CSR read is single-cycle pulse
    property p_rd_single_cycle;
        @(posedge clk) disable iff (!rst_n)
            csr_rd_en |-> ##1 (csr_rd_en == 1'b0);
    endproperty
    assert property(p_rd_single_cycle) else
        $error("CSR_IF ASSERT: csr_rd_en not single-cycle pulse");

    // CHK_003: CSR addr/wdata valid during write
    property p_wr_addr_data_valid;
        @(posedge clk) disable iff (!rst_n)
            csr_wr_en |-> !$isunknown(csr_addr) && !$isunknown(csr_wdata);
    endproperty
    assert property(p_wr_addr_data_valid) else
        $error("CSR_IF ASSERT: csr_addr or csr_wdata unknown during write");

    // CHK_003: CSR addr valid during read
    property p_rd_addr_valid;
        @(posedge clk) disable iff (!rst_n)
            csr_rd_en |-> !$isunknown(csr_addr);
    endproperty
    assert property(p_rd_addr_valid) else
        $error("CSR_IF ASSERT: csr_addr unknown during read");

    // CHK_003: CSR read returns data 1 cycle after rd_en
    property p_rd_data_next_cycle;
        @(posedge clk) disable iff (!rst_n)
            csr_rd_en |-> ##1 !$isunknown(csr_rdata);
    endproperty
    assert property(p_rd_data_next_cycle) else
        $error("CSR_IF ASSERT: csr_rdata unknown 1 cycle after csr_rd_en");

    // CHK_003: CSR address range check (0x00-0x3F)
    property p_addr_range;
        @(posedge clk) disable iff (!rst_n)
            (csr_wr_en || csr_rd_en) |-> (csr_addr < 8'h40);
    endproperty
    assert property(p_addr_range) else
        $error("CSR_IF ASSERT: csr_addr out of range (>= 0x40) during access");

    // CHK_001: CSR outputs deasserted after reset
    property p_reset_csr_outputs;
        @(posedge clk) !rst_n |=> (csr_rd_en == 1'b0 && csr_wr_en == 1'b0);
    endproperty
    assert property(p_reset_csr_outputs) else
        $error("CSR_IF ASSERT: csr_rd_en or csr_wr_en not deasserted after reset");

    // CHK_003: csr_rd_en and csr_wr_en should not be simultaneous
    property p_no_rw_simultaneous;
        @(posedge clk) disable iff (!rst_n)
            !(csr_rd_en && csr_wr_en);
    endproperty
    assert property(p_no_rw_simultaneous) else
        $error("CSR_IF ASSERT: csr_rd_en and csr_wr_en asserted simultaneously");

    `endif

endinterface

`endif
