`ifndef SPI_TYPES_SV
`define SPI_TYPES_SV

typedef virtual spi_if spi_vif_t;

typedef enum logic [7:0] {
  SPI_STS_OK          = 8'h00,
  SPI_STS_FRAME_ERR   = 8'h01,
  SPI_STS_BAD_OPCODE  = 8'h02,
  SPI_STS_NOT_IN_TEST = 8'h04,
  SPI_STS_DISABLED    = 8'h08,
  SPI_STS_BAD_REG     = 8'h10,
  SPI_STS_ALIGN_ERR   = 8'h20,
  SPI_STS_AHB_ERR     = 8'h40,
  SPI_STS_BAD_BURST   = 8'h80,
  SPI_STS_BURST_BOUND = 8'h81
} spi_status_t;

typedef enum logic [7:0] {
  SPI_WR_CSR       = 8'h10,
  SPI_RD_CSR       = 8'h11,
  SPI_AHB_WR32     = 8'h20,
  SPI_AHB_RD32     = 8'h21,
  SPI_AHB_WR_BURST = 8'h22,
  SPI_AHB_RD_BURST = 8'h23
} spi_opcode_t;

typedef enum logic [1:0] {
  SPI_LANE_1BIT  = 2'b00,
  SPI_LANE_4BIT  = 2'b01,
  SPI_LANE_8BIT  = 2'b10,
  SPI_LANE_16BIT = 2'b11
} spi_lane_mode_t;

typedef enum logic [2:0] {
  SPI_HBURST_SINGLE = 3'b000,
  SPI_HBURST_INCR4  = 3'b011,
  SPI_HBURST_INCR8  = 3'b101,
  SPI_HBURST_INCR16 = 3'b111
} spi_hburst_t;

typedef enum {
  SPI_REQUEST,
  SPI_RESPONSE
} spi_direction_t;

`endif // SPI_TYPES_SV
