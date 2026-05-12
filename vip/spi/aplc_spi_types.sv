`ifndef APLC_SPI_TYPES_SV
`define APLC_SPI_TYPES_SV

typedef enum logic [7:0] {
    APLC_OP_WR_CSR     = 8'h10,
    APLC_OP_RD_CSR     = 8'h11,
    APLC_OP_AHB_WR32   = 8'h20,
    APLC_OP_AHB_RD32   = 8'h21,
    APLC_OP_AHB_WR_BURST = 8'h22,
    APLC_OP_AHB_RD_BURST = 8'h23
} aplc_opcode_e;

typedef enum logic [7:0] {
    APLC_STS_OK          = 8'h00,
    APLC_STS_FRAME_ERR   = 8'h01,
    APLC_STS_BAD_OPCODE  = 8'h02,
    APLC_STS_NOT_IN_TEST = 8'h04,
    APLC_STS_DISABLED    = 8'h08,
    APLC_STS_BAD_REG     = 8'h10,
    APLC_STS_ALIGN_ERR   = 8'h20,
    APLC_STS_AHB_ERR     = 8'h40,
    APLC_STS_BAD_BURST   = 8'h80,
    APLC_STS_BURST_BOUND = 8'h81
} aplc_status_e;

typedef enum logic [1:0] {
    APLC_LANE_1BIT  = 2'b00,
    APLC_LANE_4BIT  = 2'b01,
    APLC_LANE_8BIT  = 2'b10,
    APLC_LANE_16BIT = 2'b11
} aplc_lane_mode_e;

typedef enum logic [2:0] {
    APLC_HBURST_SINGLE = 3'b000,
    APLC_HBURST_INCR4  = 3'b011,
    APLC_HBURST_INCR8  = 3'b101,
    APLC_HBURST_INCR16 = 3'b111
} aplc_hburst_e;

`endif
