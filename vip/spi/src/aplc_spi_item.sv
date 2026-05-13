// APLC SPI transaction item (driver request)
`ifndef APLC_SPI_ITEM_SV
`define APLC_SPI_ITEM_SV

class aplc_spi_item extends uvm_sequence_item;

    // Command fields
    rand aplc_opcode_e   opcode;
    rand logic [7:0]     reg_addr;   // CSR address
    rand logic [31:0]    addr;       // AHB address
    rand logic [31:0]    wdata[];    // write data array (1 for single, N for burst)
    rand logic [4:0]     burst_len;  // burst length (1/4/8/16)

    // Configuration fields
    rand aplc_lane_mode_e lane_mode;

    // Response fields (filled by driver after collecting response)
    rand logic [7:0]     status;
    rand logic [31:0]    rdata[];    // read data array

    // Protocol flags
    rand bit             frame_abort;    // indicates frame was aborted
    rand bit             lane_changed;   // lane mode changed during txn
    rand bit             ta_err;         // turnaround error

    `uvm_object_utils(aplc_spi_item)

    function new(string name = "aplc_spi_item");
        super.new(name);
        frame_abort  = 1'b0;
        lane_changed = 1'b0;
        ta_err       = 1'b0;
    endfunction

    // Constrain burst_len to legal values
    constraint c_burst_len {
        if (opcode inside {APLC_OP_AHB_WR_BURST, APLC_OP_AHB_RD_BURST})
            burst_len inside {5'd1, 5'd4, 5'd8, 5'd16};
        else
            burst_len == 5'd0;
    }

    // Constrain wdata size based on opcode
    constraint c_wdata_size {
        solve opcode before wdata;
        solve burst_len before wdata;
        if (opcode == APLC_OP_WR_CSR)
            wdata.size() == 1;
        else if (opcode == APLC_OP_AHB_WR32)
            wdata.size() == 1;
        else if (opcode == APLC_OP_AHB_WR_BURST)
            wdata.size() == burst_len;
        else
            wdata.size() == 0;
    }

    // Constrain reg_addr to valid range
    constraint c_reg_addr {
        if (opcode inside {APLC_OP_WR_CSR, APLC_OP_RD_CSR})
            reg_addr < 8'h40;
    }

    // Constrain AHB address alignment
    constraint c_addr_align {
        if (opcode inside {APLC_OP_AHB_WR32, APLC_OP_AHB_RD32,
                          APLC_OP_AHB_WR_BURST, APLC_OP_AHB_RD_BURST})
            addr[1:0] == 2'b00;
    }

    // Constrain lane mode
    constraint c_lane_mode {
        lane_mode inside {APLC_LANE_1BIT, APLC_LANE_4BIT,
                         APLC_LANE_8BIT, APLC_LANE_16BIT};
    }

    function void post_randomize();
        if (opcode inside {APLC_OP_AHB_RD32, APLC_OP_RD_CSR}) begin
            rdata = new[1];
        end else if (opcode == APLC_OP_AHB_RD_BURST) begin
            rdata = new[burst_len];
        end
    endfunction

    // Calculate request frame length in bits
    function int get_request_bits();
        case (opcode)
            APLC_OP_WR_CSR:       return 48;  // 8+8+32
            APLC_OP_RD_CSR:       return 16;  // 8+8
            APLC_OP_AHB_WR32:     return 72;  // 8+32+32
            APLC_OP_AHB_RD32:     return 40;  // 8+32
            APLC_OP_AHB_WR_BURST: return 48 + 32 * burst_len;
            APLC_OP_AHB_RD_BURST: return 48;  // header only
            default:              return 0;
        endcase
    endfunction

    // Calculate response frame length in bits
    function int get_response_bits();
        case (opcode)
            APLC_OP_WR_CSR:       return 8;
            APLC_OP_RD_CSR:       return 40;  // 8+32
            APLC_OP_AHB_WR32:     return 8;
            APLC_OP_AHB_RD32:     return 40;  // 8+32
            APLC_OP_AHB_WR_BURST: return 8;
            APLC_OP_AHB_RD_BURST: return 8 + 32 * burst_len;
            default:              return 0;
        endcase
    endfunction

    // Get bits per clock based on lane mode
    function int get_bpc();
        case (lane_mode)
            APLC_LANE_1BIT:  return 1;
            APLC_LANE_4BIT:  return 4;
            APLC_LANE_8BIT:  return 8;
            APLC_LANE_16BIT: return 16;
            default:         return 16;
        endcase
    endfunction

    // Get burst header as 48-bit vector
    function logic [47:0] get_burst_header();
        logic [47:0] hdr;
        hdr[47:40] = opcode;
        hdr[39:35] = burst_len;
        hdr[34:32] = 3'b000; // reserved
        hdr[31:0]  = addr;
        return hdr;
    endfunction

    // Convert request to bit stream (MSB-first)
    function void get_request_bits_stream(ref logic queue[$]);
        logic [79:0] frame;
        int total_bits;

        queue.delete();
        total_bits = get_request_bits();

        if (opcode inside {APLC_OP_AHB_WR_BURST, APLC_OP_AHB_RD_BURST}) begin
            // Burst: header(48) + optional payload
            frame = get_burst_header();
            for (int i = 47; i >= 0; i--)
                queue.push_back(frame[i]);
            // Payload for write burst
            if (opcode == APLC_OP_AHB_WR_BURST) begin
                for (int w = 0; w < wdata.size; w++) begin
                    for (int i = 31; i >= 0; i--)
                        queue.push_back(wdata[w][i]);
                end
            end
        end else begin
            // Non-burst commands
            case (opcode)
                APLC_OP_WR_CSR: begin
                    frame[79:72] = opcode;
                    frame[71:64] = reg_addr;
                    frame[63:32] = wdata[0];
                    for (int i = total_bits - 1; i >= 0; i--)
                        queue.push_back(frame[i + (80 - total_bits)]);
                end
                APLC_OP_RD_CSR: begin
                    frame[79:72] = opcode;
                    frame[71:64] = reg_addr;
                    for (int i = total_bits - 1; i >= 0; i--)
                        queue.push_back(frame[i + (80 - total_bits)]);
                end
                APLC_OP_AHB_WR32: begin
                    frame[79:72] = opcode;
                    frame[71:40] = addr;
                    frame[39:8]  = wdata[0];
                    for (int i = total_bits - 1; i >= 0; i--)
                        queue.push_back(frame[i + (80 - total_bits)]);
                end
                APLC_OP_AHB_RD32: begin
                    frame[79:72] = opcode;
                    frame[71:40] = addr;
                    for (int i = total_bits - 1; i >= 0; i--)
                        queue.push_back(frame[i + (80 - total_bits)]);
                end
                default: ;
            endcase
        end
    endfunction

    virtual function string convert2string();
        string s;
        s = $sformatf("opcode=%s lane=%0d", opcode.name(), lane_mode);
        if (opcode inside {APLC_OP_WR_CSR, APLC_OP_RD_CSR})
            s = {s, $sformatf(" reg_addr=0x%02h", reg_addr)};
        if (opcode inside {APLC_OP_AHB_WR32, APLC_OP_AHB_RD32,
                          APLC_OP_AHB_WR_BURST, APLC_OP_AHB_RD_BURST})
            s = {s, $sformatf(" addr=0x%08h", addr)};
        if (opcode inside {APLC_OP_WR_CSR, APLC_OP_AHB_WR32})
            s = {s, $sformatf(" wdata=0x%08h", wdata[0])};
        if (opcode inside {APLC_OP_AHB_WR_BURST})
            s = {s, $sformatf(" burst_len=%0d", burst_len)};
        s = {s, $sformatf(" status=0x%02h", status)};
        if (rdata.size() > 0 && rdata[0] !== 32'bx)
            s = {s, $sformatf(" rdata[0]=0x%08h", rdata[0])};
        if (frame_abort)  s = {s, " FRAME_ABORT"};
        if (lane_changed) s = {s, " LANE_CHANGED"};
        if (ta_err)       s = {s, " TA_ERR"};
        return s;
    endfunction

    virtual function void do_copy(uvm_object rhs);
        aplc_spi_item other;
        super.do_copy(rhs);
        if (!$cast(other, rhs)) return;
        opcode     = other.opcode;
        reg_addr   = other.reg_addr;
        addr       = other.addr;
        wdata      = other.wdata;
        burst_len  = other.burst_len;
        lane_mode  = other.lane_mode;
        status     = other.status;
        rdata      = other.rdata;
        frame_abort  = other.frame_abort;
        lane_changed = other.lane_changed;
        ta_err       = other.ta_err;
    endfunction

    virtual function bit do_compare(uvm_object rhs, uvm_comparer comparer);
        aplc_spi_item other;
        if (!$cast(other, rhs)) return 0;
        return super.do_compare(rhs, comparer) &&
               opcode     == other.opcode &&
               reg_addr   == other.reg_addr &&
               addr       == other.addr &&
               burst_len  == other.burst_len &&
               status     == other.status;
    endfunction

endclass

`endif
