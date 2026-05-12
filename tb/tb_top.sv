// APLC-Lite Testbench Top Module

`timescale 1ns/1ps

module tb_top;

    import uvm_pkg::*;
    import aplc_spi_pkg::*;
    import yuu_common_pkg::*;
    import yuu_ahb_pkg::*;

    // ------------------------------------------------
    // Clock and Reset Generation
    // ------------------------------------------------
    logic clk;
    logic rst_n;

    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // 100MHz
    end

    initial begin
        rst_n = 0;
        #200 rst_n = 1;
    end

    // ------------------------------------------------
    // DUT Signals
    // ------------------------------------------------
    logic        en;
    logic        test_mode;
    logic        pcs_n;
    logic [15:0] pdi;
    logic [15:0] pdo;
    logic        pdo_oe;
    logic [1:0]  lane_mode;
    logic        rxfifo_empty;
    logic        rxfifo_full;
    logic        txfifo_empty;
    logic        txfifo_full;

    logic        csr_rd_en;
    logic        csr_wr_en;
    logic [7:0]  csr_addr;
    logic [31:0] csr_wdata;
    logic [31:0] csr_rdata;

    logic [31:0] haddr;
    logic        hwrite;
    logic [1:0]  htrans;
    logic [2:0]  hsize;
    logic [2:0]  hburst;
    logic [31:0] hwdata;
    logic [31:0] hrdata;
    logic        hready;
    logic        hresp;

    // ------------------------------------------------
    // SPI Interface Instantiation
    // ------------------------------------------------
    aplc_spi_if spi_if (
        .clk(clk),
        .rst_n(rst_n)
    );

    // Connect SPI interface to DUT signals
    assign pcs_n       = spi_if.pcs_n;
    assign pdi         = spi_if.pdi;
    assign en          = spi_if.en;
    assign test_mode   = spi_if.test_mode;
    assign lane_mode   = spi_if.lane_mode;
    assign spi_if.pdo           = pdo;
    assign spi_if.pdo_oe       = pdo_oe;
    assign spi_if.rxfifo_empty = rxfifo_empty;
    assign spi_if.rxfifo_full  = rxfifo_full;
    assign spi_if.txfifo_empty = txfifo_empty;
    assign spi_if.txfifo_full  = txfifo_full;

    // ------------------------------------------------
    // CSR Interface Instantiation
    // ------------------------------------------------
    aplc_csr_if csr_if (
        .clk(clk),
        .rst_n(rst_n)
    );

    assign csr_if.csr_rd_en = csr_rd_en;
    assign csr_if.csr_wr_en = csr_wr_en;
    assign csr_if.csr_addr  = csr_addr;
    assign csr_if.csr_wdata = csr_wdata;
    assign csr_rdata        = csr_if.csr_rdata;

    // ------------------------------------------------
    // AHB Interface Instantiation (yuu_ahb slave)
    // ------------------------------------------------
    yuu_ahb_interface ahb_if();

    assign ahb_if.hclk     = clk;
    assign ahb_if.hreset_n = rst_n;

    // Connect AHB slave interface[0] to DUT master outputs
    assign ahb_if.slave_if[0].hsel     = 1'b1;
    assign ahb_if.slave_if[0].haddr    = haddr;
    assign ahb_if.slave_if[0].htrans   = htrans;
    assign ahb_if.slave_if[0].hburst   = hburst;
    assign ahb_if.slave_if[0].hwrite   = hwrite;
    assign ahb_if.slave_if[0].hsize    = hsize;
    assign ahb_if.slave_if[0].hwdata   = hwdata;
    assign ahb_if.slave_if[0].hprot    = 4'b0011;
    assign ahb_if.slave_if[0].hready_i = ahb_if.slave_if[0].hready_o;
    assign hrdata = ahb_if.slave_if[0].hrdata;
    assign hresp  = ahb_if.slave_if[0].hresp;
    assign hready = ahb_if.slave_if[0].hready_o;

    // ------------------------------------------------
    // DUT Instantiation
    // ------------------------------------------------
    APLC_LITE #(
        .IO_MAX_W(16),
        .ADDR_W(32),
        .DATA_W(32)
    ) u_dut (
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

    // ------------------------------------------------
    // FSDB Waveform Dump
    // ------------------------------------------------
    `ifdef DUMP_FSDB
    initial begin
        $fsdbDumpfile("aplc_tb.fsdb");
        $fsdbDumpvars(0, tb_top);
    end
    `endif

    // ------------------------------------------------
    // UVM Configuration and Start
    // ------------------------------------------------
    initial begin
        aplc_spi_agent_config spi_cfg;
        yuu_ahb_slave_config  ahb_cfg;
        aplc_env_config       env_cfg;

        // SPI agent config
        spi_cfg = aplc_spi_agent_config::type_id::create("spi_cfg");
        spi_cfg.is_active         = UVM_ACTIVE;
        spi_cfg.has_coverage      = 1;
        spi_cfg.has_checks        = 1;
        spi_cfg.default_lane_mode = APLC_LANE_16BIT;
        spi_cfg.default_en        = 1'b1;
        spi_cfg.default_test_mode = 1'b1;
        spi_cfg.set_vif(spi_if);

        // AHB slave config
        ahb_cfg = yuu_ahb_slave_config::type_id::create("ahb_cfg");
        ahb_cfg.index                 = 0;
        ahb_cfg.is_active             = UVM_ACTIVE;
        ahb_cfg.coverage_enable       = False;
        ahb_cfg.analysis_enable       = False;
        ahb_cfg.protocol_check_enable = True;
        ahb_cfg.vif                   = ahb_if.get_slave_if(0);
        ahb_cfg.wait_enable           = True;
        ahb_cfg.events                = new("ahb_events");
        ahb_cfg.set_map(32'h0000_0000, 32'hFFFF_FFFF);

        // Env config
        env_cfg = aplc_env_config::type_id::create("env_cfg");
        env_cfg.has_spi_agent = 1;
        env_cfg.has_ahb_agent = 1;
        env_cfg.has_csr_file  = 1;
        env_cfg.spi_cfg       = spi_cfg;
        env_cfg.ahb_cfg       = ahb_cfg;
        env_cfg.csr_vif       = csr_if;

        uvm_config_db#(aplc_env_config)::set(null, "*", "env_config", env_cfg);
        uvm_config_db#(aplc_spi_agent_config)::set(null, "*", "agent_config", spi_cfg);
        uvm_config_db#(virtual aplc_csr_if)::set(null, "*", "csr_vif", csr_if);
        uvm_config_db#(yuu_ahb_slave_config)::set(null, "*", "cfg", ahb_cfg);

        run_test();
    end

endmodule
