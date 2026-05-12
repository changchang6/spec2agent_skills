`ifndef APLC_SPI_TYPES_SV
`define APLC_SPI_TYPES_SV

typedef virtual aplc_spi_if aplc_spi_vif_t;

typedef enum bit [7:0] {
    APLC_SPI_WR_CSR      = 8'h10,
    APLC_SPI_RD_CSR      = 8'h11,
    APLC_SPI_AHB_WR32    = 8'h20,
    APLC_SPI_AHB_RD32    = 8'h21,
    APLC_SPI_AHB_WR_BURST = 8'h22,
    APLC_SPI_AHB_RD_BURST = 8'h23
} aplc_spi_opcode_t;

typedef enum bit [1:0] {
    APLC_SPI_CMD_CSR  = 2'b00,
    APLC_SPI_CMD_AHB  = 2'b01,
    APLC_SPI_CMD_RSVD = 2'b10
} aplc_spi_cmd_type_t;

typedef enum bit [7:0] {
    APLC_SPI_STS_OK          = 8'h00,
    APLC_SPI_STS_FRAME_ERR   = 8'h01,
    APLC_SPI_STS_BAD_OPCODE  = 8'h02,
    APLC_SPI_STS_NOT_IN_TEST = 8'h04,
    APLC_SPI_STS_DISABLED    = 8'h08,
    APLC_SPI_STS_BAD_REG     = 8'h10,
    APLC_SPI_STS_ALIGN_ERR   = 8'h20,
    APLC_SPI_STS_AHB_ERR     = 8'h40,
    APLC_SPI_STS_BAD_BURST   = 8'h80,
    APLC_SPI_STS_BURST_BOUND = 8'h81
} aplc_spi_status_t;

typedef enum bit [1:0] {
    APLC_SPI_LANE_1BIT  = 2'b00,
    APLC_SPI_LANE_4BIT  = 2'b01,
    APLC_SPI_LANE_8BIT  = 2'b10,
    APLC_SPI_LANE_16BIT = 2'b11
} aplc_spi_lane_mode_t;

typedef enum bit [2:0] {
    APLC_SPI_HBURST_SINGLE = 3'b000,
    APLC_SPI_HBURST_INCR4  = 3'b011,
    APLC_SPI_HBURST_INCR8  = 3'b101,
    APLC_SPI_HBURST_INCR16 = 3'b111
} aplc_spi_hburst_t;

`endif
