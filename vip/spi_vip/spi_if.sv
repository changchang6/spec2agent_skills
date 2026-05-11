`ifndef SPI_IF_SV
`define SPI_IF_SV

interface spi_if(input clk);

  // Clock and reset
  logic        rst_n;

  // Control signals (driven by testbench/agent_config)
  logic        en;
  logic        test_mode;
  logic [1:0]  lane_mode;

  // SPI bus signals
  logic        pcs_n;       // Chip select, active low
  logic [15:0] pdi;         // Parallel data input (ATE -> DUT)
  logic [15:0] pdo;         // Parallel data output (DUT -> ATE)
  logic        pdo_oe;      // Output enable from DUT

  // FIFO status
  logic        rxfifo_empty;
  logic        rxfifo_full;
  logic        txfifo_empty;
  logic        txfifo_full;

  // Clocking block for driver
  clocking driver_cb @(posedge clk);
    output   pcs_n, pdi;
    input    pdo, pdo_oe;
    input    rxfifo_empty, rxfifo_full, txfifo_empty, txfifo_full;
  endclocking

  // Clocking block for monitor
  clocking monitor_cb @(posedge clk);
    input    pcs_n, pdi, pdo, pdo_oe;
    input    rst_n, en, test_mode, lane_mode;
    input    rxfifo_empty, rxfifo_full, txfifo_empty, txfifo_full;
  endclocking

  modport driver(clocking driver_cb, output lane_mode);
  modport monitor(clocking monitor_cb);

endinterface : spi_if

`endif // SPI_IF_SV
