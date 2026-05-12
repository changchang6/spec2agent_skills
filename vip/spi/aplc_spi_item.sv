`ifndef APLC_SPI_ITEM_SV
`define APLC_SPI_ITEM_SV

class aplc_spi_item extends uvm_sequence_item;
    `uvm_object_utils(aplc_spi_item)

    rand aplc_opcode_e   opcode;
    rand logic [7:0]     reg_addr;
    rand logic [31:0]    addr;
    rand logic [31:0]    wdata;
    rand logic [4:0]     burst_len;
    rand aplc_lane_mode_e lane_mode;

    logic [7:0]           status;
    logic [31:0]          rdata;
    logic [31:0]          wdata_q[$];
    logic [31:0]          rdata_q[$];
    logic                 frame_abort;

    constraint c_opcode_valid {
        opcode inside {APLC_OP_WR_CSR, APLC_OP_RD_CSR,
                       APLC_OP_AHB_WR32, APLC_OP_AHB_RD32,
                       APLC_OP_AHB_WR_BURST, APLC_OP_AHB_RD_BURST};
    }

    constraint c_burst_len_valid {
        if (opcode inside {APLC_OP_AHB_WR_BURST, APLC_OP_AHB_RD_BURST})
            burst_len inside {5'd4, 5'd8, 5'd16};
        else
            burst_len == 5'd0;
    }

    constraint c_addr_aligned {
        if (opcode inside {APLC_OP_AHB_WR32, APLC_OP_AHB_RD32,
                           APLC_OP_AHB_WR_BURST, APLC_OP_AHB_RD_BURST})
            addr[1:0] == 2'b00;
    }

    constraint c_reg_addr_range {
        if (opcode inside {APLC_OP_WR_CSR, APLC_OP_RD_CSR})
            reg_addr < 8'h40;
    }

    function new(string name = "aplc_spi_item");
        super.new(name);
    endfunction

    function void post_randomize();
        super.post_randomize();
        if (opcode == APLC_OP_AHB_WR_BURST) begin
            wdata_q.delete();
            for (int i = 0; i < burst_len; i++)
                wdata_q.push_back($urandom_range(32'hFFFF_FFFF));
        end else begin
            wdata_q.delete();
        end
    endfunction

    virtual function void do_copy(uvm_object rhs);
        aplc_spi_item rhs_;
        super.do_copy(rhs);
        if (!$cast(rhs_, rhs)) return;
        opcode      = rhs_.opcode;
        reg_addr    = rhs_.reg_addr;
        addr        = rhs_.addr;
        wdata       = rhs_.wdata;
        burst_len   = rhs_.burst_len;
        lane_mode   = rhs_.lane_mode;
        status      = rhs_.status;
        rdata       = rhs_.rdata;
        frame_abort = rhs_.frame_abort;
        wdata_q     = rhs_.wdata_q;
        rdata_q     = rhs_.rdata_q;
    endfunction

    virtual function bit do_compare(uvm_object rhs, uvm_comparer comparer);
        aplc_spi_item rhs_;
        if (!$cast(rhs_, rhs)) return 0;
        return super.do_compare(rhs, comparer) &&
               opcode == rhs_.opcode &&
               reg_addr == rhs_.reg_addr &&
               addr == rhs_.addr &&
               wdata == rhs_.wdata &&
               burst_len == rhs_.burst_len &&
               lane_mode == rhs_.lane_mode;
    endfunction

    virtual function string convert2string();
        string s;
        s = $sformatf("opcode=%0s reg_addr=0x%02h addr=0x%08h wdata=0x%08h burst_len=%0d lane=%0s",
                       opcode.name(), reg_addr, addr, wdata, burst_len, lane_mode.name());
        s = {s, $sformatf(" status=0x%02h rdata=0x%08h frame_abort=%0b",
                          status, rdata, frame_abort)};
        return s;
    endfunction

    virtual function void do_print(uvm_printer printer);
        printer.m_string = convert2string();
    endfunction

    virtual function int get_request_bits();
        case (opcode)
            APLC_OP_WR_CSR:       return 48;
            APLC_OP_RD_CSR:       return 16;
            APLC_OP_AHB_WR32:     return 72;
            APLC_OP_AHB_RD32:     return 40;
            APLC_OP_AHB_WR_BURST: return 48 + 32 * burst_len;
            APLC_OP_AHB_RD_BURST: return 48;
            default:              return 0;
        endcase
    endfunction

    virtual function int get_response_bits();
        case (opcode)
            APLC_OP_WR_CSR,
            APLC_OP_AHB_WR32,
            APLC_OP_AHB_WR_BURST: return 8;
            APLC_OP_RD_CSR,
            APLC_OP_AHB_RD32:     return 40;
            APLC_OP_AHB_RD_BURST: return 8 + 32 * burst_len;
            default:              return 0;
        endcase
    endfunction

endclass

`endif
