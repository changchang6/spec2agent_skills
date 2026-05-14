`ifndef SPI_TRANSACTION_SV
`define SPI_TRANSACTION_SV

class spi_transaction extends uvm_sequence_item;

    rand spi_opcode_e    opcode;
    rand logic [7:0]     reg_addr;
    rand logic [`ADDR_WIDTH-1:0] addr;
    rand logic [`DATA_WIDTH-1:0] wdata;
    rand logic [`DATA_WIDTH-1:0] wdata_queue [];
    rand logic [`DATA_WIDTH-1:0] rdata [];
    rand spi_lane_mode_e lane_mode;
    rand logic [4:0]     burst_len;
    rand logic [2:0]     hburst;
    rand spi_status_e    status;

    rand bit              frame_abort;
    rand bit              is_read;

    int                   response_len_bits;

    `uvm_object_utils_begin(spi_transaction)
        `uvm_field_enum(spi_opcode_e, opcode, UVM_ALL_ON)
        `uvm_field_int(reg_addr, UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(addr, UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(wdata, UVM_ALL_ON | UVM_HEX)
        `uvm_field_array_int(wdata_queue, UVM_ALL_ON | UVM_HEX)
        `uvm_field_array_int(rdata, UVM_ALL_ON | UVM_HEX)
        `uvm_field_enum(spi_lane_mode_e, lane_mode, UVM_ALL_ON)
        `uvm_field_int(burst_len, UVM_ALL_ON)
        `uvm_field_int(hburst, UVM_ALL_ON)
        `uvm_field_enum(spi_status_e, status, UVM_ALL_ON)
        `uvm_field_int(frame_abort, UVM_ALL_ON)
        `uvm_field_int(is_read, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "spi_transaction");
        super.new(name);
        rdata = new[0];
        wdata_queue = new[0];
    endfunction

    virtual function int get_lane_width();
        case(lane_mode)
            LANE_MODE_1BIT:  return 1;
            LANE_MODE_4BIT:  return 4;
            LANE_MODE_8BIT:  return 8;
            LANE_MODE_16BIT: return 16;
            default:         return 16;
        endcase
    endfunction

    virtual function int get_request_bits();
        case(opcode)
            OPC_WR_CSR:     return 48;
            OPC_RD_CSR:     return 16;
            OPC_AHB_WR32:   return 72;
            OPC_AHB_RD32:   return 40;
            OPC_AHB_WR_BURST: return 48 + 32 * burst_len;
            OPC_AHB_RD_BURST: return 48;
            default:        return 0;
        endcase
    endfunction

    virtual function int get_response_bits();
        case(opcode)
            OPC_WR_CSR,
            OPC_AHB_WR32,
            OPC_AHB_WR_BURST: return 8;
            OPC_RD_CSR,
            OPC_AHB_RD32:     return 40;
            OPC_AHB_RD_BURST: return 8 + 32 * burst_len;
            default:          return 8;
        endcase
    endfunction

    virtual function bit has_rdata();
        return (opcode inside {OPC_RD_CSR, OPC_AHB_RD32, OPC_AHB_RD_BURST});
    endfunction

    virtual function bit is_burst_cmd();
        return (opcode inside {OPC_AHB_WR_BURST, OPC_AHB_RD_BURST});
    endfunction

    function void post_randomize();
        case(opcode)
            OPC_RD_CSR, OPC_AHB_RD32: begin
                is_read = 1;
            end
            OPC_AHB_RD_BURST: begin
                is_read = 1;
            end
            default: begin
                is_read = 0;
            end
        endcase
        if(is_burst_cmd()) begin
            case(burst_len)
                5'd1:  hburst = HBURST_SINGLE;
                5'd4:  hburst = HBURST_INCR4;
                5'd8:  hburst = HBURST_INCR8;
                5'd16: hburst = HBURST_INCR16;
                default: hburst = HBURST_SINGLE;
            endcase
            // Initialize burst write data queue
            if(opcode == OPC_AHB_WR_BURST) begin
                wdata_queue = new[burst_len];
                foreach(wdata_queue[i]) begin
                    wdata_queue[i] = $urandom();
                end
            end
        end else begin
            hburst = HBURST_SINGLE;
        end
    endfunction

endclass : spi_transaction

`endif
