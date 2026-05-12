`timescale 1ns/1ps

`ifndef APLC_TB_TOP_SV
`define APLC_TB_TOP_SV

module aplc_tb_top;

    logic        clk;
    logic        rst_n;
    logic        en;
    logic        test_mode;
    logic [1:0]  lane_mode;

    // SPI interface wires
    wire         pcs_n;
    wire [15:0]  pdi;
    wire [15:0]  pdo;
    wire         pdo_oe;
    wire         rxfifo_empty;
    wire         rxfifo_full;
    wire         txfifo_empty;
    wire         txfifo_full;

    // CSR external interface
    logic        csr_rd_en;
    logic        csr_wr_en;
    logic [7:0]  csr_addr;
    logic [31:0] csr_wdata;
    logic [31:0] csr_rdata;

    // AHB interface wires (DUT drives outputs, TB drives inputs)
    wire [31:0]  haddr;
    wire         hwrite;
    wire [1:0]   htrans;
    wire [2:0]   hsize;
    wire [2:0]   hburst;
    wire [31:0]  hwdata;
    logic [31:0] hrdata;
    logic        hready;
    logic        hresp;

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Reset generation
    initial begin
        rst_n = 0;
        #100 rst_n = 1;
    end

    // Control signals
    initial begin
        en         = 1;
        test_mode  = 1;
        lane_mode  = 2'b11;
    end

    // -------------------------------------------------------
    // AHB-Lite Slave Memory Model (2-phase pipeline)
    // -------------------------------------------------------
    logic [31:0] ahb_mem [logic [31:0]];

    logic [31:0] ahb_addr_latch;
    logic        ahb_write_latch;
    logic        ahb_data_phase;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            hready          <= 1'b1;
            hresp           <= 1'b0;
            hrdata          <= 32'h0;
            ahb_addr_latch  <= 32'h0;
            ahb_write_latch <= 1'b0;
            ahb_data_phase  <= 1'b0;
        end else begin
            hresp  <= 1'b0;
            hready <= 1'b1;

            // Data phase: process latched address from previous cycle
            if (ahb_data_phase) begin
                if (ahb_write_latch) begin
                    ahb_mem[ahb_addr_latch] <= hwdata;
                end else begin
                    if (ahb_mem.exists(ahb_addr_latch))
                        hrdata <= ahb_mem[ahb_addr_latch];
                    else
                        hrdata <= 32'h0;
                end
            end

            // Address phase: latch current address/control
            if (htrans == 2'b10 || htrans == 2'b11) begin
                ahb_addr_latch  <= haddr;
                ahb_write_latch <= hwrite;
                ahb_data_phase  <= 1'b1;
            end else begin
                ahb_data_phase <= 1'b0;
            end
        end
    end

    // External CSR rdata (for undefined addresses, return 0)
    assign csr_rdata = 32'h0;

    // -------------------------------------------------------
    // SPI interface instance
    // -------------------------------------------------------
    aplc_spi_if u_spi_if (
        .clk(clk),
        .rst_n(rst_n)
    );

    // Connect SPI interface: driver outputs -> DUT inputs
    assign pcs_n = u_spi_if.pcs_n;
    assign pdi   = u_spi_if.pdi;

    // Connect SPI interface: DUT outputs -> monitor inputs
    assign u_spi_if.pdo           = pdo;
    assign u_spi_if.pdo_oe        = pdo_oe;
    assign u_spi_if.en            = en;
    assign u_spi_if.test_mode     = test_mode;
    assign u_spi_if.lane_mode     = lane_mode;
    assign u_spi_if.rxfifo_empty  = rxfifo_empty;
    assign u_spi_if.rxfifo_full   = rxfifo_full;
    assign u_spi_if.txfifo_empty  = txfifo_empty;
    assign u_spi_if.txfifo_full   = txfifo_full;

    // -------------------------------------------------------
    // DUT instance
    // -------------------------------------------------------
    APLC_LITE u_dut (
        .clk_i          (clk),
        .rst_n_i        (rst_n),
        .en_i           (en),
        .test_mode_i    (test_mode),
        .pcs_n_i        (pcs_n),
        .pdi_i          (pdi),
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
    // UVM initialization
    // -------------------------------------------------------
    import uvm_pkg::*;
    import aplc_spi_pkg::*;
    import aplc_tb_pkg::*;

    initial begin
        uvm_config_db #(virtual aplc_spi_if)::set(null, "uvm_test_top.m_env.m_spi_agent*", "m_vif", u_spi_if);
        run_test();
    end

    // Waveform dump
    `ifdef DUMP_FSDB
    initial begin
        $fsdbDumpfile("aplc_tb.fsdb");
        $fsdbDumpvars(0, aplc_tb_top);
    end
    `endif

endmodule

`endif
