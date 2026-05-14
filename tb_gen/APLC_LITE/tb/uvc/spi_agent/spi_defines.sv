`ifndef SPI_DEFINES_SV
`define SPI_DEFINES_SV

`include "uvm_macros.svh"
import uvm_pkg::*;

// AI gen: Opcode definitions per LRS v2.2 Table 3.3.1
`define OPC_WR_CSR       8'h10
`define OPC_RD_CSR       8'h11
`define OPC_AHB_WR32     8'h20
`define OPC_AHB_RD32     8'h21
`define OPC_AHB_WR_BURST 8'h22
`define OPC_AHB_RD_BURST 8'h23

// AI gen: Status code definitions per LRS v2.2 Table 3.4.2
`define STS_OK           8'h00
`define STS_FRAME_ERR    8'h01
`define STS_BAD_OPCODE   8'h02
`define STS_NOT_IN_TEST  8'h04
`define STS_DISABLED     8'h08
`define STS_BAD_REG      8'h10
`define STS_ALIGN_ERR    8'h20
`define STS_AHB_ERR      8'h40
`define STS_BAD_BURST    8'h80
`define STS_BURST_BOUND  8'h81

// AI gen: Lane mode definitions per LRS v2.2 Table 3.2
`define LANE_MODE_1BIT   2'b00
`define LANE_MODE_4BIT   2'b01
`define LANE_MODE_8BIT   2'b10
`define LANE_MODE_16BIT  2'b11

// AI gen: AHB burst type definitions per LRS v2.2 Table 3.3.2
`define HBURST_SINGLE    3'b000
`define HBURST_INCR4     3'b011
`define HBURST_INCR8     3'b101
`define HBURST_INCR16    3'b111

// AI gen: Frame bit widths per LRS v2.2 Table 3.1.1
`define WR_CSR_FRAME_BITS    48
`define RD_CSR_FRAME_BITS    16
`define AHB_WR32_FRAME_BITS  72
`define AHB_RD32_FRAME_BITS  40
`define BURST_HEADER_BITS    48

`define ADDR_WIDTH  32
`define DATA_WIDTH  32
`define CSR_ADDR_WIDTH 8
`define MAX_LANE_WIDTH 16

`endif
