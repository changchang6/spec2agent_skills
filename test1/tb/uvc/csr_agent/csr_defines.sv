`ifndef CSR_DEFINES_SV
`define CSR_DEFINES_SV

`include "uvm_macros.svh"
import uvm_pkg::*;

`define ADDR_WIDTH 32
`define DATA_WIDTH 32
`define CSR_ADDR_WIDTH 8

// CSR address map
typedef enum logic [7:0] {
    CSR_ADDR_VERSION   = 8'h00,
    CSR_ADDR_CTRL      = 8'h04,
    CSR_ADDR_STATUS    = 8'h08,
    CSR_ADDR_LAST_ERR  = 8'h0C,
    CSR_ADDR_BURST_CNT = 8'h10
} csr_addr_e;

// STATUS register bit positions
typedef struct packed {
    logic       busy;
    logic       resp_valid;
    logic       cmd_err;
    logic       bus_err;
    logic       frame_err;
    logic       in_test_mode;
    logic       out_en;
    logic       burst_err;
} csr_status_s;

`endif
