`ifndef APLC_TB_TOP_SV
`define APLC_TB_TOP_SV

module aplc_tb_top;

    import uvm_pkg::*;
    `include "uvm_macros.svh"
    import aplc_spi_pkg::*;
    import yuu_ahb_pkg::*;
    import aplc_tb_pkg::*;

    logic clk;
    logic rst_n;

    // -------------------------------------------------------
    // Clock generation: 100MHz, 10ns period
    // -------------------------------------------------------
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // -------------------------------------------------------
    // Reset generation
    // -------------------------------------------------------
    initial begin
        rst_n = 1'b0;
        #53 rst_n = 1'b1;
    end

    // -------------------------------------------------------
    // SPI interface - connects TB driver/monitor to DUT
    // -------------------------------------------------------
    aplc_spi_if spi_if (
        .clk(clk),
        .rst_n(rst_n)
    );

    // DUT control signals (directly driven by TB top)
    logic        en        = 1'b1;
    logic        test_mode = 1'b1;
    logic [1:0]  lane_mode = 2'b11;

    assign spi_if.en        = en;
    assign spi_if.test_mode = test_mode;
    assign spi_if.lane_mode = lane_mode;

    // DUT <-> SPI interface connections
    logic [15:0] pdo;
    logic        pdo_oe;
    logic        rxfifo_empty, rxfifo_full, txfifo_empty, txfifo_full;

    assign spi_if.pdo          = pdo;
    assign spi_if.pdo_oe       = pdo_oe;
    assign spi_if.rxfifo_empty = rxfifo_empty;
    assign spi_if.rxfifo_full  = rxfifo_full;
    assign spi_if.txfifo_empty = txfifo_empty;
    assign spi_if.txfifo_full  = txfifo_full;

    // -------------------------------------------------------
    // AHB interface (yuu_ahb slave VIP)
    // -------------------------------------------------------
    yuu_ahb_interface ahb_if();

    assign ahb_if.hclk     = clk;
    assign ahb_if.hreset_n = rst_n;

    // AHB signals from DUT
    logic [31:0] haddr;
    logic        hwrite;
    logic [1:0]  htrans;
    logic [2:0]  hsize;
    logic [2:0]  hburst;
    logic [31:0] hwdata;
    logic [31:0] hrdata;
    logic        hready;
    logic        hresp;

    // Connect DUT master outputs to AHB slave interface
    logic hready_mux;
    assign ahb_if.slave_if[0].haddr     = haddr;
    assign ahb_if.slave_if[0].htrans    = htrans;
    assign ahb_if.slave_if[0].hburst    = hburst;
    assign ahb_if.slave_if[0].hwrite    = hwrite;
    assign ahb_if.slave_if[0].hsize     = hsize;
    assign ahb_if.slave_if[0].hwdata    = hwdata;
    assign ahb_if.slave_if[0].hprot     = 4'b0011;
    assign ahb_if.slave_if[0].hprot_emt = 4'b0000;
    assign ahb_if.slave_if[0].hmaster   = 4'b0000;
    assign ahb_if.slave_if[0].hmastlock = 1'b0;
    assign ahb_if.slave_if[0].hnonsec   = 1'b0;
    assign ahb_if.slave_if[0].hsel      = (htrans != 2'b00);
    assign ahb_if.slave_if[0].hready_i  = hready_mux;
    assign hready_mux = ahb_if.slave_if[0].hready_o;
    assign hrdata     = ahb_if.slave_if[0].hrdata;
    assign hresp      = ahb_if.slave_if[0].hresp[0];

    // -------------------------------------------------------
    // CSR external interface
    // -------------------------------------------------------
    logic        csr_rd_en;
    logic        csr_wr_en;
    logic [7:0]  csr_addr;
    logic [31:0] csr_wdata;
    logic [31:0] csr_rdata;

    // Simple external CSR model for addresses beyond internal range (0x14+)
    logic [31:0] ext_csr_rdata_q;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            ext_csr_rdata_q <= 32'h0;
        else if (csr_rd_en)
            ext_csr_rdata_q <= 32'h0;
    end
    assign csr_rdata = ext_csr_rdata_q;

    // -------------------------------------------------------
    // DUT instantiation
    // -------------------------------------------------------
    APLC_LITE dut (
        .clk_i          (clk),
        .rst_n_i        (rst_n),
        .en_i           (en),
        .test_mode_i    (test_mode),
        .pcs_n_i        (spi_if.pcs_n),
        .pdi_i          (spi_if.pdi),
        .pdo_o          (pdo),
        .pdo_oe_o       (pdo_oe),
        .lane_mode_i    (lane_mode),
        .rxfifo_empty_o (rxfifo_empty),
        .rxfifo_full_o  (rxfifo_full),
        .txfifo_empty_o (txfifo_empty),
        .txfifo_full_o  (txfifo_full),
        .csr_rd_en_o    (csr_rd_en),
        .csr_wr_en_o    (csr_wr_en),
        .csr_addr_o     (csr_addr),
        .csr_wdata_o    (csr_wdata),
        .csr_rdata_i    (csr_rdata),
        .haddr_o        (haddr),
        .hwrite_o       (hwrite),
        .htrans_o       (htrans),
        .hsize_o        (hsize),
        .hburst_o       (hburst),
        .hwdata_o       (hwdata),
        .hrdata_i       (hrdata),
        .hready_i       (hready),
        .hresp_i        (hresp)
    );

    // -------------------------------------------------------
    // Waveform dump (FSDB format, default on)
    // -------------------------------------------------------
    initial begin
        `ifdef DUMP_FSDB
            $fsdbDumpfile("aplc_tb.fsdb");
            $fsdbDumpvars(0, aplc_tb_top);
        `endif
    end

    // -------------------------------------------------------
    // UVM configuration and start
    // -------------------------------------------------------
    initial begin
        uvm_config_db #(virtual aplc_spi_if)::set(uvm_root::get(), "uvm_test_top", "aplc_spi_if", spi_if);
        uvm_config_db #(virtual yuu_ahb_interface)::set(uvm_root::get(), "uvm_test_top", "yuu_ahb_interface", ahb_if);
        run_test();
    end

endmodule

`endif
