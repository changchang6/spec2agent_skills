`ifndef APLC_SPI_ITEM_SV
`define APLC_SPI_ITEM_SV

class aplc_spi_item extends uvm_sequence_item;

    `uvm_object_utils(aplc_spi_item)

    rand aplc_spi_opcode_t   opcode;
    rand bit [4:0]           burst_len;
    rand bit [7:0]           reg_addr;
    rand bit [31:0]          addr;
    rand bit [31:0]          wdata[];
    rand bit [1:0]           lane_mode;

    rand bit                 inject_error;
    rand bit [7:0]           error_opcode;
    rand bit [7:0]           error_reg_addr;
    rand bit [31:0]          error_addr;
    rand bit [4:0]           error_burst_len;

    bit [7:0]                status;
    bit [31:0]               rdata[];

    constraint wdata_size_c {
        solve opcode before wdata;
        opcode == APLC_SPI_WR_CSR   -> wdata.size() == 1;
        opcode == APLC_SPI_AHB_WR32 -> wdata.size() == 1;
        opcode == APLC_SPI_AHB_WR_BURST -> wdata.size() == burst_len;
        opcode inside {APLC_SPI_RD_CSR, APLC_SPI_AHB_RD32, APLC_SPI_AHB_RD_BURST} -> wdata.size() == 0;
    }

    constraint addr_align_c {
        solve opcode before addr;
        opcode inside {APLC_SPI_AHB_WR32, APLC_SPI_AHB_RD32,
                       APLC_SPI_AHB_WR_BURST, APLC_SPI_AHB_RD_BURST} -> addr[1:0] == 2'b00;
    }

    constraint burst_len_legal_c {
        solve opcode before burst_len;
        opcode inside {APLC_SPI_AHB_WR_BURST, APLC_SPI_AHB_RD_BURST} -> burst_len inside {1, 4, 8, 16};
        opcode inside {APLC_SPI_WR_CSR, APLC_SPI_RD_CSR,
                       APLC_SPI_AHB_WR32, APLC_SPI_AHB_RD32} -> burst_len == 0;
    }

    constraint reg_addr_legal_c {
        solve opcode before reg_addr;
        opcode inside {APLC_SPI_WR_CSR, APLC_SPI_RD_CSR} -> reg_addr < 8'h40;
    }

    constraint lane_mode_legal_c {
        lane_mode inside {2'b00, 2'b01, 2'b10, 2'b11};
    }

    constraint no_error_by_default_c {
        soft inject_error == 0;
    }

    function new(string name = "aplc_spi_item");
        super.new(name);
    endfunction

    function void pre_randomize();
    endfunction

    virtual function bit [2:0] get_hburst();
        case (burst_len)
            5'd1:  return APLC_SPI_HBURST_SINGLE;
            5'd4:  return APLC_SPI_HBURST_INCR4;
            5'd8:  return APLC_SPI_HBURST_INCR8;
            5'd16: return APLC_SPI_HBURST_INCR16;
            default: return APLC_SPI_HBURST_SINGLE;
        endcase
    endfunction

    virtual function int get_rx_bits();
        case (opcode)
            APLC_SPI_WR_CSR:       return 48;
            APLC_SPI_RD_CSR:       return 16;
            APLC_SPI_AHB_WR32:     return 72;
            APLC_SPI_AHB_RD32:     return 40;
            APLC_SPI_AHB_WR_BURST: return 48 + 32 * burst_len;
            APLC_SPI_AHB_RD_BURST: return 48;
            default:               return 0;
        endcase
    endfunction

    virtual function int get_tx_bits();
        if (status != APLC_SPI_STS_OK) begin
            return 8;
        end
        case (opcode)
            APLC_SPI_WR_CSR:       return 8;
            APLC_SPI_RD_CSR:       return 40;
            APLC_SPI_AHB_WR32:     return 8;
            APLC_SPI_AHB_RD32:     return 40;
            APLC_SPI_AHB_WR_BURST: return 8;
            APLC_SPI_AHB_RD_BURST: return 8 + 32 * burst_len;
            default:               return 8;
        endcase
    endfunction

    virtual function int get_bpc();
        case (lane_mode)
            2'b00: return 1;
            2'b01: return 4;
            2'b10: return 8;
            2'b11: return 16;
            default: return 1;
        endcase
    endfunction

    virtual function string convert2string();
        string s;
        s = $sformatf("opcode:%s reg_addr:0x%02h addr:0x%08h burst_len:%0d lane_mode:%0d",
                       opcode.name(), reg_addr, addr, burst_len, lane_mode);
        if (wdata.size() > 0) begin
            s = {s, $sformatf(" wdata[%0d]:", wdata.size())};
            foreach (wdata[i]) s = {s, $sformatf("0x%08h ", wdata[i])};
        end
        s = {s, $sformatf(" status:0x%02h", status)};
        if (rdata.size() > 0) begin
            s = {s, $sformatf(" rdata[%0d]:", rdata.size())};
            foreach (rdata[i]) s = {s, $sformatf("0x%08h ", rdata[i])};
        end
        return s;
    endfunction

    virtual function void do_copy(uvm_object rhs);
        aplc_spi_item other;
        super.do_copy(rhs);
        if (!$cast(other, rhs)) return;
        opcode       = other.opcode;
        burst_len    = other.burst_len;
        reg_addr     = other.reg_addr;
        addr         = other.addr;
        wdata        = other.wdata;
        lane_mode    = other.lane_mode;
        status       = other.status;
        rdata        = other.rdata;
        inject_error = other.inject_error;
        error_opcode = other.error_opcode;
        error_reg_addr = other.error_reg_addr;
        error_addr   = other.error_addr;
        error_burst_len = other.error_burst_len;
    endfunction

    virtual function bit do_compare(uvm_object rhs, uvm_comparer comparer);
        aplc_spi_item other;
        if (!$cast(other, rhs)) return 0;
        return super.do_compare(rhs, comparer) &&
               opcode    == other.opcode &&
               burst_len == other.burst_len &&
               reg_addr  == other.reg_addr &&
               addr      == other.addr &&
               status    == other.status;
    endfunction

endclass

`endif
