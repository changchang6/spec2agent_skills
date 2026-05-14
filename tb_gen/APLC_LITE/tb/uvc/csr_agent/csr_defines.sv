`ifndef CSR_DEFINES_SV
`define CSR_DEFINES_SV

`include "uvm_macros.svh"
import uvm_pkg::*;

// AI gen: CSR address map per LRS v2.2 Table 4.6.3
`define CSR_ADDR_VERSION   8'h00
`define CSR_ADDR_CTRL      8'h04
`define CSR_ADDR_STATUS    8'h08
`define CSR_ADDR_LAST_ERR  8'h0C
`define CSR_ADDR_BURST_CNT 8'h10

// AI gen: CSR address range
`define CSR_ADDR_MIN       8'h00
`define CSR_ADDR_MAX       8'h3F

// AI gen: STATUS register bit positions per LRS v2.2 Table 4.5
`define STATUS_BIT_BUSY         0
`define STATUS_BIT_RESP_VALID   1
`define STATUS_BIT_CMD_ERR      2
`define STATUS_BIT_BUS_ERR      3
`define STATUS_BIT_FRAME_ERR    4
`define STATUS_BIT_IN_TEST_MODE 5
`define STATUS_BIT_OUT_EN       6
`define STATUS_BIT_BURST_ERR    7

`define ADDR_WIDTH  32
`define DATA_WIDTH  32

`endif
