`ifndef TB_TOP_SV
`define TB_TOP_SV

module tb_top;

  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import spi_pkg::*;
  import aplc_tb_pkg::*;

  // Clock generation
  logic clk;
  initial begin
    clk = 0;
    forever #5 clk = ~clk;  // 100MHz, 10ns period
  end

  // Reset generation
  logic rst_n;
  initial begin
    rst_n = 0;
    #100 rst_n = 1;
  end

  // SPI interface
  spi_if spi_vif(.clk(clk));

  // AHB signals
  logic [31:0] hrdata;
  logic        hready;
  logic        hresp;

  // CSR signals
  logic [31:0] csr_rdata;

  // DUT instance
  APLC_LITE u_dut (
    .clk_i         (clk),
    .rst_n_i       (rst_n),
    .en_i          (spi_vif.en),
    .test_mode_i   (spi_vif.test_mode),
    .pcs_n_i       (spi_vif.pcs_n),
    .pdi_i         (spi_vif.pdi),
    .pdo_o         (spi_vif.pdo),
    .pdo_oe_o      (spi_vif.pdo_oe),
    .lane_mode_i   (spi_vif.lane_mode),
    .rxfifo_empty_o(spi_vif.rxfifo_empty),
    .rxfifo_full_o (spi_vif.rxfifo_full),
    .txfifo_empty_o(spi_vif.txfifo_empty),
    .txfifo_full_o (spi_vif.txfifo_full),
    // CSR interface
    .csr_rd_en_o   (),
    .csr_wr_en_o   (),
    .csr_addr_o    (),
    .csr_wdata_o   (),
    .csr_rdata_i   (csr_rdata),
    // AHB master interface
    .haddr_o       (),
    .hwrite_o      (),
    .htrans_o      (),
    .hsize_o       (),
    .hburst_o      (),
    .hwdata_o      (),
    .hrdata_i      (hrdata),
    .hready_i      (hready),
    .hresp_i       (hresp)
  );

  // Simple AHB slave responder
  logic [31:0] ahb_haddr_q;
  logic        ahb_hwrite_q;
  logic [31:0] ahb_mem [logic];

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      hrdata     <= 32'h0;
      hready     <= 1'b1;
      hresp      <= 1'b0;
      ahb_haddr_q <= 32'h0;
      ahb_hwrite_q <= 1'b0;
    end else begin
      // Default
      hready <= 1'b1;
      hresp  <= 1'b0;

      // Latch address phase
      if (u_dut.htrans_o == 2'b10 || u_dut.htrans_o == 2'b11) begin // NONSEQ or SEQ
        ahb_haddr_q  <= u_dut.haddr_o;
        ahb_hwrite_q <= u_dut.hwrite_o;
      end

      // Data phase response
      if (ahb_hwrite_q && (u_dut.htrans_o != 2'b00)) begin
        // Write: store data
        ahb_mem[ahb_haddr_q] = u_dut.hwdata_o;
      end else if (!ahb_hwrite_q) begin
        // Read: return data
        if (ahb_mem.exists(ahb_haddr_q))
          hrdata <= ahb_mem[ahb_haddr_q];
        else
          hrdata <= 32'hDEAD_BEEF;
      end
    end
  end

  // Simple CSR read responder
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      csr_rdata <= 32'h0;
    else if (u_dut.csr_rd_en_o)
      csr_rdata <= 32'h0000_0000; // Default read data for external CSR
  end

  // Connect reset to SPI interface
  assign spi_vif.rst_n = rst_n;

  // FSDB waveform dump
  `ifdef DUMP_FSDB
  initial begin
    $fsdbDumpfile("aplc_tb.fsdb");
    $fsdbDumpvars(0, tb_top);
  end
  `endif

  // Set interface in config_db
  initial begin
    uvm_config_db#(spi_vif_t)::set(null, "uvm_test_top", "spi_vif", spi_vif);
    run_test();
  end

endmodule : tb_top

`endif // TB_TOP_SV
