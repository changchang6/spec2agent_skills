`ifndef SPI_ITEM_SV
`define SPI_ITEM_SV

class spi_item extends uvm_sequence_item;

  `uvm_object_utils(spi_item)

  // Command fields (request)
  rand spi_opcode_t   opcode;
  rand logic [4:0]    burst_len;
  rand logic [7:0]    reg_addr;
  rand logic [31:0]   addr;
  rand logic [31:0]   wdata[];

  // Response fields
  rand spi_status_t   status;
  rand logic [31:0]   rdata[];

  // Configuration
  rand spi_lane_mode_t lane_mode;

  constraint burst_len_valid {
    if (opcode inside {SPI_AHB_WR_BURST, SPI_AHB_RD_BURST})
      burst_len inside {1, 4, 8, 16};
    else
      burst_len == 0;
  }

  constraint wdata_size {
    if (opcode == SPI_WR_CSR)
      wdata.size() == 1;
    else if (opcode == SPI_AHB_WR32)
      wdata.size() == 1;
    else if (opcode == SPI_AHB_WR_BURST)
      wdata.size() == burst_len;
    else
      wdata.size() == 0;
  }

  constraint rdata_size {
    if (opcode == SPI_RD_CSR)
      rdata.size() == 1;
    else if (opcode == SPI_AHB_RD32)
      rdata.size() == 1;
    else if (opcode == SPI_AHB_RD_BURST)
      rdata.size() == burst_len;
    else
      rdata.size() == 0;
  }

  constraint addr_aligned {
    if (opcode inside {SPI_AHB_WR32, SPI_AHB_RD32,
                       SPI_AHB_WR_BURST, SPI_AHB_RD_BURST})
      addr[1:0] == 2'b00;
  }

  constraint reg_addr_valid {
    if (opcode inside {SPI_WR_CSR, SPI_RD_CSR})
      reg_addr < 8'h40;
  }

  function new(string name = "spi_item");
    super.new(name);
  endfunction

  virtual function void do_copy(uvm_object rhs);
    spi_item rhs_;
    super.do_copy(rhs);
    if (!$cast(rhs_, rhs)) return;
    opcode    = rhs_.opcode;
    burst_len = rhs_.burst_len;
    reg_addr  = rhs_.reg_addr;
    addr      = rhs_.addr;
    wdata     = rhs_.wdata;
    status    = rhs_.status;
    rdata     = rhs_.rdata;
    lane_mode = rhs_.lane_mode;
  endfunction

  virtual function bit do_compare(uvm_object rhs, uvm_comparer comparer);
    spi_item rhs_;
    if (!$cast(rhs_, rhs)) return 0;
    return (super.do_compare(rhs, comparer) &&
            opcode    == rhs_.opcode &&
            burst_len == rhs_.burst_len &&
            reg_addr  == rhs_.reg_addr &&
            addr      == rhs_.addr &&
            status    == rhs_.status &&
            lane_mode == rhs_.lane_mode &&
            wdata     == rhs_.wdata &&
            rdata     == rhs_.rdata);
  endfunction

  virtual function string convert2string();
    string s;
    s = $sformatf("opcode=%s lane=%s burst=%0d reg_addr=0x%02h addr=0x%08h status=%s",
                   opcode.name(), lane_mode.name(), burst_len, reg_addr, addr, status.name());
    if (wdata.size() > 0) begin
      s = {s, " wdata=["};
      foreach (wdata[i]) begin
        if (i > 0) s = {s, ","};
        s = {s, $sformatf("0x%08h", wdata[i])};
      end
      s = {s, "]"};
    end
    if (rdata.size() > 0) begin
      s = {s, " rdata=["};
      foreach (rdata[i]) begin
        if (i > 0) s = {s, ","};
        s = {s, $sformatf("0x%08h", rdata[i])};
      end
      s = {s, "]"};
    end
    return s;
  endfunction

  virtual function void do_print(uvm_printer printer);
    printer.print_string("opcode",    opcode.name());
    printer.print_string("lane_mode", lane_mode.name());
    printer.print_int("burst_len",    burst_len, $bits(burst_len));
    printer.print_int("reg_addr",     reg_addr,  $bits(reg_addr));
    printer.print_int("addr",         addr,      $bits(addr));
    printer.print_string("status",    status.name());
    foreach (wdata[i])
      printer.print_int($sformatf("wdata[%0d]", i), wdata[i], $bits(wdata[i]));
    foreach (rdata[i])
      printer.print_int($sformatf("rdata[%0d]", i), rdata[i], $bits(rdata[i]));
  endfunction

  virtual function void do_record(uvm_recorder recorder);
    super.do_record(recorder);
    `uvm_record_field("opcode",    opcode)
    `uvm_record_field("burst_len", burst_len)
    `uvm_record_field("reg_addr",  reg_addr)
    `uvm_record_field("addr",      addr)
    `uvm_record_field("status",    status)
    `uvm_record_field("lane_mode", lane_mode)
  endfunction

  virtual function int unsigned get_request_bits();
    case (opcode)
      SPI_WR_CSR:       return 48;
      SPI_RD_CSR:       return 16;
      SPI_AHB_WR32:     return 72;
      SPI_AHB_RD32:     return 40;
      SPI_AHB_WR_BURST: return 48 + 32 * burst_len;
      SPI_AHB_RD_BURST: return 48;
      default:          return 8;
    endcase
  endfunction

  virtual function int unsigned get_response_bits();
    case (opcode)
      SPI_WR_CSR, SPI_AHB_WR32, SPI_AHB_WR_BURST:
        return 8;
      SPI_RD_CSR, SPI_AHB_RD32:
        return 40;
      SPI_AHB_RD_BURST:
        return 8 + 32 * burst_len;
      default:
        return 8;
    endcase
  endfunction

  virtual function int unsigned get_bits_per_clock();
    case (lane_mode)
      SPI_LANE_1BIT:  return 1;
      SPI_LANE_4BIT:  return 4;
      SPI_LANE_8BIT:  return 8;
      SPI_LANE_16BIT: return 16;
      default:        return 1;
    endcase
  endfunction

  virtual function int unsigned get_request_clocks();
    int bpc = get_bits_per_clock();
    return (get_request_bits() + bpc - 1) / bpc;
  endfunction

  virtual function int unsigned get_response_clocks();
    int bpc = get_bits_per_clock();
    return (get_response_bits() + bpc - 1) / bpc;
  endfunction

  // Pack request frame into bit vector (MSB first, MSB at position 559)
  virtual function logic [559:0] pack_request();
    logic [559:0] frame;
    int idx;
    frame = '0;
    idx = 559;
    // Opcode (8 bits)
    frame[idx-:8] = opcode;
    idx -= 8;

    case (opcode)
      SPI_WR_CSR: begin
        frame[idx-:8]  = reg_addr; idx -= 8;
        frame[idx-:32] = wdata[0]; idx -= 32;
      end
      SPI_RD_CSR: begin
        frame[idx-:8] = reg_addr; idx -= 8;
      end
      SPI_AHB_WR32: begin
        frame[idx-:32] = addr;    idx -= 32;
        frame[idx-:32] = wdata[0]; idx -= 32;
      end
      SPI_AHB_RD32: begin
        frame[idx-:32] = addr; idx -= 32;
      end
      SPI_AHB_WR_BURST, SPI_AHB_RD_BURST: begin
        frame[idx-:5]  = burst_len; idx -= 5;
        frame[idx-:3]  = 3'b000;    idx -= 3;
        frame[idx-:32] = addr;      idx -= 32;
        if (opcode == SPI_AHB_WR_BURST) begin
          foreach (wdata[i]) begin
            frame[idx-:32] = wdata[i]; idx -= 32;
          end
        end
      end
      default: ; // illegal opcode: just 8 bits
    endcase
    return frame;
  endfunction

  // Pack response frame into bit vector (MSB first, MSB at position 559)
  virtual function logic [559:0] pack_response();
    logic [559:0] frame;
    int idx;
    frame = '0;
    idx = 559;
    // Status (8 bits)
    frame[idx-:8] = status;
    idx -= 8;

    case (opcode)
      SPI_RD_CSR, SPI_AHB_RD32: begin
        frame[idx-:32] = rdata[0]; idx -= 32;
      end
      SPI_AHB_RD_BURST: begin
        foreach (rdata[i]) begin
          frame[idx-:32] = rdata[i]; idx -= 32;
        end
      end
      default: ; // write commands: only status
    endcase
    return frame;
  endfunction

endclass : spi_item

`endif // SPI_ITEM_SV
