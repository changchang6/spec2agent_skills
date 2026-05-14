`ifndef SPI_DEFINES_SV
`define SPI_DEFINES_SV

`include "uvm_macros.svh"
import uvm_pkg::*;

`define ADDR_WIDTH 32
`define DATA_WIDTH 32
`define CSR_ADDR_WIDTH 8
`define MAX_LANE_WIDTH 16
`define MAX_FRAME_BITS 560

// Opcode definitions
typedef enum logic [7:0] {
    OPC_WR_CSR     = 8'h10,
    OPC_RD_CSR     = 8'h11,
    OPC_AHB_WR32   = 8'h20,
    OPC_AHB_RD32   = 8'h21,
    OPC_AHB_WR_BURST = 8'h22,
    OPC_AHB_RD_BURST = 8'h23
} spi_opcode_e;

// Status code definitions
typedef enum logic [7:0] {
    STS_OK           = 8'h00,
    STS_FRAME_ERR    = 8'h01,
    STS_BAD_OPCODE   = 8'h02,
    STS_NOT_IN_TEST  = 8'h04,
    STS_DISABLED     = 8'h08,
    STS_BAD_REG      = 8'h10,
    STS_ALIGN_ERR    = 8'h20,
    STS_AHB_ERR      = 8'h40,
    STS_BAD_BURST    = 8'h80,
    STS_BURST_BOUND  = 8'h81
} spi_status_e;

// Lane mode definitions
typedef enum logic [1:0] {
    LANE_MODE_1BIT  = 2'b00,
    LANE_MODE_4BIT  = 2'b01,
    LANE_MODE_8BIT  = 2'b10,
    LANE_MODE_16BIT = 2'b11
} spi_lane_mode_e;

// AHB burst type
typedef enum logic [2:0] {
    HBURST_SINGLE = 3'b000,
    HBURST_INCR4  = 3'b011,
    HBURST_INCR8  = 3'b101,
    HBURST_INCR16 = 3'b111
} spi_hburst_e;

// Frame start timing mode
typedef enum {
    FRAME_START_OFFSET_EDGE,
    FRAME_START_SAME_EDGE
} spi_frame_start_e;

// Frame end timing mode
typedef enum {
    FRAME_END_AFTER_RESPONSE,
    FRAME_END_AFTER_REQUEST
} spi_frame_end_e;

// Turnaround control mode
typedef enum {
    TA_BY_DUT,
    TA_BY_MASTER
} spi_ta_mode_e;

`endif
