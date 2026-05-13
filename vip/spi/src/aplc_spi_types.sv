// APLC SPI VIP type definitions
`ifndef APLC_SPI_TYPES_SV
`define APLC_SPI_TYPES_SV

// Lane mode encoding (matches DUT lane_mode_i)
typedef enum logic [1:0] {
    APLC_LANE_1BIT  = 2'b00,
    APLC_LANE_4BIT  = 2'b01,
    APLC_LANE_8BIT  = 2'b10,
    APLC_LANE_16BIT = 2'b11
} aplc_lane_mode_e;

// Opcode definitions
typedef enum logic [7:0] {
    APLC_OP_WR_CSR      = 8'h10,
    APLC_OP_RD_CSR      = 8'h11,
    APLC_OP_AHB_WR32    = 8'h20,
    APLC_OP_AHB_RD32    = 8'h21,
    APLC_OP_AHB_WR_BURST = 8'h22,
    APLC_OP_AHB_RD_BURST = 8'h23
} aplc_opcode_e;

// Status code definitions
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

// Command type
typedef enum logic [1:0] {
    APLC_CMD_CSR        = 2'b00,
    APLC_CMD_AHB_SINGLE = 2'b01,
    APLC_CMD_AHB_BURST  = 2'b10
} aplc_cmd_type_e;

// AHB burst encoding
typedef enum logic [2:0] {
    APLC_HBURST_SINGLE = 3'b000,
    APLC_HBURST_INCR4  = 3'b011,
    APLC_HBURST_INCR8  = 3'b101,
    APLC_HBURST_INCR16 = 3'b111
} aplc_hburst_e;

// Timing constants extracted from LRS
// Frame start timing: pcs_n_i and first data appear on same clock edge (same-edge mode)
// LRS §4.8.1~4.8.5: pcs_n_i goes low and pdi_i first data appears simultaneously
localparam int FRAME_START_OFFSET_EDGE = 0; // same-edge mode

// Frame end timing: pcs_n_i releases after response complete
localparam int FRAME_END_AFTER_RESPONSE = 1; // release after response

// Turnaround: DUT controls turnaround via pdo_oe_o
localparam int TA_BY_DUT = 1; // DUT inserts turnaround

// Burst continuity: payload beats are continuous with header
localparam int BURST_CONTINUOUS = 1; // no gap between beats

// FIFO backpressure exists
localparam int HAS_RXFIFO_FULL  = 1; // rxfifo_full_o exists
localparam int HAS_TXFIFO_EMPTY = 1; // txfifo_empty_o exists

// Turnaround duration in clock cycles
localparam int TA_CYCLES = 1;

// Data width
localparam int DATA_W = 16;

// CSR address width
localparam int CSR_ADDR_W = 8;

// AHB address width
localparam int ADDR_W = 32;

`endif
