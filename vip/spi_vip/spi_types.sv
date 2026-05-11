/******************************************************************************
 * SPI VIP Types
 * Description: Type definitions for SPI VIP
 ******************************************************************************/

`ifndef SPI_TYPES_SV
`define SPI_TYPES_SV

typedef virtual spi_if spi_vif_t;

typedef enum bit [1:0] {
    LANE_MODE_1BIT  = 2'b00,
    LANE_MODE_4BIT  = 2'b01,
    LANE_MODE_8BIT  = 2'b10,
    LANE_MODE_16BIT = 2'b11
} spi_lane_mode_t;

typedef enum bit [7:0] {
    CMD_WR_CSR       = 8'h10,
    CMD_RD_CSR       = 8'h11,
    CMD_AHB_WR32     = 8'h20,
    CMD_AHB_RD32     = 8'h21,
    CMD_AHB_WR_BURST = 8'h22,
    CMD_AHB_RD_BURST = 8'h23
} spi_opcode_t;

typedef enum bit [7:0] {
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
} spi_status_t;

typedef enum bit {
    DIR_WRITE = 1'b1,
    DIR_READ  = 1'b0
} spi_direction_t;

typedef enum bit {
    CMD_TYPE_CSR = 1'b0,
    CMD_TYPE_AHB = 1'b1
} spi_cmd_type_t;

typedef enum bit [2:0] {
    HBURST_SINGLE = 3'b000,
    HBURST_INCR4  = 3'b011,
    HBURST_INCR8  = 3'b101,
    HBURST_INCR16 = 3'b111
} spi_hburst_t;

typedef bit [`SPI_MAX_DATA_WIDTH-1:0] spi_data_t;
typedef bit [`SPI_MAX_ADDR_WIDTH-1:0] spi_addr_t;

function automatic int get_bits_per_cycle(spi_lane_mode_t lane_mode);
    case(lane_mode)
        LANE_MODE_1BIT:  return 1;
        LANE_MODE_4BIT:  return 4;
        LANE_MODE_8BIT:  return 8;
        LANE_MODE_16BIT: return 16;
        default: return 16;
    endcase
endfunction

function automatic string lane_mode_to_string(spi_lane_mode_t lane_mode);
    case(lane_mode)
        LANE_MODE_1BIT:  return "1-bit";
        LANE_MODE_4BIT:  return "4-bit";
        LANE_MODE_8BIT:  return "8-bit";
        LANE_MODE_16BIT: return "16-bit";
        default: return "Unknown";
    endcase
endfunction

function automatic string opcode_to_string(spi_opcode_t opcode);
    case(opcode)
        CMD_WR_CSR:       return "WR_CSR";
        CMD_RD_CSR:       return "RD_CSR";
        CMD_AHB_WR32:     return "AHB_WR32";
        CMD_AHB_RD32:     return "AHB_RD32";
        CMD_AHB_WR_BURST: return "AHB_WR_BURST";
        CMD_AHB_RD_BURST: return "AHB_RD_BURST";
        default: return "UNKNOWN";
    endcase
endfunction

function automatic string status_to_string(spi_status_t status);
    case(status)
        STS_OK:          return "OK";
        STS_FRAME_ERR:   return "FRAME_ERR";
        STS_BAD_OPCODE:  return "BAD_OPCODE";
        STS_NOT_IN_TEST: return "NOT_IN_TEST";
        STS_DISABLED:    return "DISABLED";
        STS_BAD_REG:     return "BAD_REG";
        STS_ALIGN_ERR:   return "ALIGN_ERR";
        STS_AHB_ERR:     return "AHB_ERR";
        STS_BAD_BURST:   return "BAD_BURST";
        STS_BURST_BOUND: return "BURST_BOUND";
        default: return "UNKNOWN";
    endcase
endfunction

`endif
