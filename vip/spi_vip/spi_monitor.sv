`ifndef SPI_MONITOR_SV
`define SPI_MONITOR_SV

class spi_monitor extends uvm_monitor;

  `uvm_component_utils(spi_monitor)

  uvm_analysis_port#(spi_mon_item) output_port;

  spi_agent_config m_agent_config;
  process m_collect_process;

  function new(string name = "spi_monitor", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    output_port = new("output_port", this);
  endfunction

  virtual task run_phase(uvm_phase phase);
    forever begin
      fork
        begin
          m_agent_config.wait_reset_end();
          collect_transactions();
        end
      join_none
      m_agent_config.wait_reset_start();
      handle_reset();
      disable fork;
    end
  endtask

  virtual function void handle_reset();
    if (m_collect_process != null) begin
      m_collect_process.kill();
      m_collect_process = null;
    end
  endfunction

  virtual task collect_transactions();
    spi_vif_t vif;
    vif = m_agent_config.get_vif();

    forever begin
      spi_mon_item req_item, rsp_item;
      logic [559:0] rx_buf;
      int unsigned  rx_count;
      int unsigned  bits_per_clock;
      spi_opcode_t  opcode_latched;
      logic [4:0]   burst_len_latched;
      int unsigned  expected_rx_bits;
      int unsigned  expected_tx_bits;
      bit           opcode_known;

      // Wait for transaction start (pcs_n = 0)
      do begin
        @(vif.monitor_cb);
      end while (vif.monitor_cb.pcs_n !== 1'b0);

      m_collect_process = process::self();

      req_item = spi_mon_item::type_id::create("req_item");
      req_item.start_time    = $time;
      req_item.direction     = SPI_REQUEST;
      req_item.en_obs        = vif.monitor_cb.en;
      req_item.test_mode_obs = vif.monitor_cb.test_mode;
      req_item.lane_mode_obs = vif.monitor_cb.lane_mode;
      req_item.lane_mode     = spi_lane_mode_t'(vif.monitor_cb.lane_mode);

      bits_per_clock = req_item.get_bits_per_clock();

      // --- Request Phase ---
      rx_buf         = '0;
      rx_count       = 0;
      opcode_latched = spi_opcode_t'('X);
      burst_len_latched = '0;
      expected_rx_bits  = 0;
      opcode_known      = 0;

      while (vif.monitor_cb.pcs_n === 1'b0) begin
        logic [15:0] pdi_sample;
        pdi_sample = vif.monitor_cb.pdi;

        // Shift in bits_per_clock bits, MSB first
        rx_buf = rx_buf << bits_per_clock;
        case (bits_per_clock)
          1:  rx_buf[0]    = pdi_sample[0];
          4:  rx_buf[3:0]  = pdi_sample[3:0];
          8:  rx_buf[7:0]  = pdi_sample[7:0];
          16: rx_buf[15:0] = pdi_sample[15:0];
        endcase
        rx_count += bits_per_clock;

        // Latch opcode after 8 bits
        if (rx_count == 8) begin
          opcode_latched = spi_opcode_t'(rx_buf[7:0]);
          req_item.opcode = opcode_latched;
          opcode_known = 1;
          case (opcode_latched)
            SPI_WR_CSR:       expected_rx_bits = 48;
            SPI_RD_CSR:       expected_rx_bits = 16;
            SPI_AHB_WR32:     expected_rx_bits = 72;
            SPI_AHB_RD32:     expected_rx_bits = 40;
            SPI_AHB_WR_BURST: expected_rx_bits = 48;
            SPI_AHB_RD_BURST: expected_rx_bits = 48;
            default:          expected_rx_bits = 8;
          endcase
        end

        // For burst commands, extract burst_len after 16 bits
        if (rx_count >= 16 && opcode_latched inside {SPI_AHB_WR_BURST, SPI_AHB_RD_BURST}) begin
          burst_len_latched = rx_buf[12:8];
          req_item.burst_len = burst_len_latched;
          if (opcode_latched == SPI_AHB_WR_BURST)
            expected_rx_bits = 48 + 32 * burst_len_latched;
        end

        // Check if request is complete
        if (expected_rx_bits > 0 && rx_count >= expected_rx_bits)
          break;

        @(vif.monitor_cb);
      end

      // Check if pcs_n went high prematurely (frame abort)
      if (vif.monitor_cb.pcs_n === 1'b1 && rx_count < expected_rx_bits) begin
        req_item.frame_aborted = 1;
        req_item.end_time = $time;
        if (opcode_known)
          req_item.status = SPI_STS_FRAME_ERR;
        parse_request(req_item, rx_buf, rx_count, opcode_latched, burst_len_latched);
        output_port.write(req_item);
        continue;
      end

      // Parse request fields
      parse_request(req_item, rx_buf, rx_count, opcode_latched, burst_len_latched);
      req_item.end_time = $time;
      output_port.write(req_item);

      // --- Wait for Response Phase ---
      // Wait for pdo_oe to go high
      while (vif.monitor_cb.pdo_oe !== 1'b1) begin
        @(vif.monitor_cb);
        if (vif.monitor_cb.pcs_n === 1'b1) begin
          // pcs_n went high without response - frame abort
          break;
        end
      end

      if (vif.monitor_cb.pdo_oe !== 1'b1) begin
        // No response received
        continue;
      end

      // --- Response Phase ---
      rsp_item = spi_mon_item::type_id::create("rsp_item");
      rsp_item.direction  = SPI_RESPONSE;
      rsp_item.opcode     = opcode_latched;
      rsp_item.burst_len  = burst_len_latched;
      rsp_item.lane_mode  = spi_lane_mode_t'(vif.monitor_cb.lane_mode);
      rsp_item.start_time = $time;

      expected_tx_bits = get_expected_response_bits(opcode_latched, burst_len_latched);

      begin
        logic [559:0] tx_buf;
        int unsigned  tx_count;
        tx_buf   = '0;
        tx_count = 0;

        while (vif.monitor_cb.pdo_oe === 1'b1) begin
          logic [15:0] pdo_sample;
          pdo_sample = vif.monitor_cb.pdo;

          tx_buf = tx_buf << bits_per_clock;
          case (bits_per_clock)
            1:  tx_buf[0]    = pdo_sample[0];
            4:  tx_buf[3:0]  = pdo_sample[3:0];
            8:  tx_buf[7:0]  = pdo_sample[7:0];
            16: tx_buf[15:0] = pdo_sample[15:0];
          endcase
          tx_count += bits_per_clock;

          rsp_item.txfifo_empty_obs = vif.monitor_cb.txfifo_empty;
          rsp_item.txfifo_full_obs  = vif.monitor_cb.txfifo_full;

          @(vif.monitor_cb);
        end

        // Parse response
        parse_response(rsp_item, tx_buf, tx_count, opcode_latched, burst_len_latched);
      end

      rsp_item.end_time = $time;
      output_port.write(rsp_item);

      // Wait for pcs_n to go high if not already
      while (vif.monitor_cb.pcs_n !== 1'b1) begin
        @(vif.monitor_cb);
      end
    end
  endtask

  virtual function void parse_request(spi_mon_item item, logic [559:0] frame_buf,
                                       int unsigned count, spi_opcode_t opcode,
                                       logic [4:0] burst_len);
    case (opcode)
      SPI_WR_CSR: begin
        item.reg_addr = frame_buf[count-9 -: 8];
        item.wdata = new[1];
        item.wdata[0] = frame_buf[count-17 -: 32];
      end
      SPI_RD_CSR: begin
        item.reg_addr = frame_buf[count-9 -: 8];
      end
      SPI_AHB_WR32: begin
        item.addr = frame_buf[count-9 -: 32];
        item.wdata = new[1];
        item.wdata[0] = frame_buf[count-41 -: 32];
      end
      SPI_AHB_RD32: begin
        item.addr = frame_buf[count-9 -: 32];
      end
      SPI_AHB_WR_BURST: begin
        item.burst_len = frame_buf[count-9 -: 5];
        item.addr = frame_buf[count-17 -: 32];
        if (burst_len > 0) begin
          item.wdata = new[burst_len];
          for (int i = 0; i < burst_len; i++)
            item.wdata[i] = frame_buf[count-49-i*32 -: 32];
        end
      end
      SPI_AHB_RD_BURST: begin
        item.burst_len = frame_buf[count-9 -: 5];
        item.addr = frame_buf[count-17 -: 32];
      end
      default: ; // illegal opcode
    endcase
  endfunction

  virtual function void parse_response(spi_mon_item item, logic [559:0] frame_buf,
                                        int unsigned count, spi_opcode_t opcode,
                                        logic [4:0] burst_len);
    if (count >= 8)
      item.status = spi_status_t'(frame_buf[count-1 -: 8]);

    case (opcode)
      SPI_RD_CSR, SPI_AHB_RD32: begin
        if (count >= 40) begin
          item.rdata = new[1];
          item.rdata[0] = frame_buf[count-9 -: 32];
        end
      end
      SPI_AHB_RD_BURST: begin
        if (count >= 8 + 32 * burst_len && burst_len > 0) begin
          item.rdata = new[burst_len];
          for (int i = 0; i < burst_len; i++)
            item.rdata[i] = frame_buf[count-9-i*32 -: 32];
        end
      end
      default: ; // write commands: only status
    endcase
  endfunction

  virtual function int unsigned get_expected_response_bits(spi_opcode_t opcode,
                                                            logic [4:0] burst_len);
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

endclass : spi_monitor

`endif // SPI_MONITOR_SV
