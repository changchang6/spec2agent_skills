// APLC TB Top Module
`ifndef APLC_TB_TOP_SV
`define APLC_TB_TOP_SV

`timescale 1ns/1ps

module tb_top;

    import uvm_pkg::*;
    import aplc_spi_pkg::*;
    import aplc_tb_pkg::*;

    // Clock and reset
    logic clk;
    logic rst_n;

    // DUT signals
    logic        en;
    logic        test_mode;
    logic [1:0]  lane_mode;

    // Instantiate SPI interface
    aplc_spi_if spi_if (
        .clk(clk),
        .rst_n(rst_n)
    );

    // Instantiate CSR interface
    aplc_csr_if csr_if (
        .clk(clk),
        .rst_n(rst_n)
    );

    // AHB signals (directly wired for yuu_ahb)
    logic [31:0] haddr;
    logic        hwrite;
    logic [1:0]  htrans;
    logic [2:0]  hsize;
    logic [2:0]  hburst;
    logic [31:0] hwdata;
    logic [31:0] hrdata;
    logic        hready;
    logic        hresp;

    // Simple AHB slave memory model
    logic [31:0] ahb_mem [logic [31:0]];

    // Clock generation - 100MHz
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Reset generation
    initial begin
        rst_n = 0;
        #100;
        rst_n = 1;
    end

    // Control signal initialization
    initial begin
        en        = 1'b1;
        test_mode = 1'b1;
        lane_mode = 2'b11; // 16-bit mode default
    end

    // DUT instantiation
    APLC_LITE dut (
        .clk_i          (clk),
        .rst_n_i        (rst_n),
        .en_i           (en),
        .test_mode_i    (test_mode),
        .pcs_n_i        (spi_if.pcs_n),
        .pdi_i          (spi_if.pdi),
        .pdo_o          (spi_if.pdo),
        .pdo_oe_o       (spi_if.pdo_oe),
        .lane_mode_i    (lane_mode),
        .rxfifo_empty_o (spi_if.rxfifo_empty),
        .rxfifo_full_o  (spi_if.rxfifo_full),
        .txfifo_empty_o (spi_if.txfifo_empty),
        .txfifo_full_o  (spi_if.txfifo_full),
        .csr_rd_en_o    (csr_if.csr_rd_en),
        .csr_wr_en_o    (csr_if.csr_wr_en),
        .csr_addr_o     (csr_if.csr_addr),
        .csr_wdata_o    (csr_if.csr_wdata),
        .csr_rdata_i    (csr_if.csr_rdata),
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

    // Simple AHB slave memory response
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            hready <= 1'b1;
            hresp  <= 1'b0;
            hrdata <= 32'b0;
        end else begin
            hready <= 1'b1;  // Always ready (zero wait state)
            hresp  <= 1'b0;  // Always OKAY
            if (htrans == 2'b10 || htrans == 2'b11) begin // NONSEQ or SEQ
                if (hwrite) begin
                    ahb_mem[haddr] = hwdata;
                end else begin
                    if (ahb_mem.exists(haddr))
                        hrdata <= ahb_mem[haddr];
                    else
                        hrdata <= 32'b0;
                end
            end
        end
    end

    // Waveform dump
    `ifdef DUMP_FSDB
    initial begin
        $fsdbDumpfile("aplc_tb.fsdb");
        $fsdbDumpvars(0, tb_top);
    end
    `endif

    // UVM configuration and start
    initial begin
        // Set virtual interface
        uvm_config_db#(virtual aplc_spi_if)::set(null, "uvm_test_top.m_env.m_spi_agent*", "vif", spi_if);

        // Create and set environment config
        aplc_env_config env_cfg;
        env_cfg = aplc_env_config::type_id::create("env_cfg");
        env_cfg.m_spi_cfg.m_vif = spi_if;
        uvm_config_db#(aplc_env_config)::set(null, "uvm_test_top", "m_env_cfg", env_cfg);

        // Run test
        run_test();
    end

endmodule

`endif
