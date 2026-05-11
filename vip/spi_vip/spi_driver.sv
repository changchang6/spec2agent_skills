`ifndef SPI_DRIVER_SV
`define SPI_DRIVER_SV

class spi_driver extends uvm_driver#(spi_drv_item, spi_drv_item);

  `uvm_component_utils(spi_driver)

  spi_agent_config m_agent_config;
  uvm_analysis_port#(spi_drv_item) output_port;
  process m_drive_process;

  function new(string name = "spi_driver", uvm_component parent = null);
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
          drive_transactions();
        end
      join_none
      m_agent_config.wait_reset_start();
      handle_reset();
      disable fork;
    end
  endtask

  virtual function void handle_reset();
    spi_vif_t vif;
    if (m_drive_process != null) begin
      m_drive_process.kill();
      m_drive_process = null;
    end
    vif = m_agent_config.get_vif();
    if (vif != null) begin
      vif.driver_cb.pcs_n <= 1'b1;
      vif.driver_cb.pdi   <= '0;
    end
  endfunction

  virtual task drive_transactions();
    forever begin
      spi_drv_item req;
      seq_item_port.get_next_item(req);
      output_port.write(req);
      m_drive_process = process::self();
      drive_transaction(req);
      seq_item_port.item_done();
    end
  endtask

  virtual task drive_transaction(spi_drv_item item);
    spi_vif_t vif;
    logic [559:0] frame;
    int unsigned  frame_bits;
    int unsigned  bits_per_clock;
    int unsigned  bits_driven;

    vif = m_agent_config.get_vif();

    // Apply driving delay
    if (m_agent_config.get_driving_delay() > 0) begin
      repeat(m_agent_config.get_driving_delay())
        @(vif.driver_cb);
    end

    // Update lane_mode on interface (async, must be stable before pcs_n assertion)
    vif.lane_mode = item.lane_mode;
    // Wait 2 cycles for lane_mode sync per spec
    @(vif.driver_cb);
    @(vif.driver_cb);

    bits_per_clock = item.get_bits_per_clock();
    frame = item.pack_request();
    frame_bits = item.get_request_bits();

    // If frame_abort, limit the number of bits driven
    if (item.frame_abort && item.abort_after_bits > 0 && item.abort_after_bits < frame_bits)
      frame_bits = item.abort_after_bits;

    // --- Request Phase ---
    vif.driver_cb.pcs_n <= 1'b0;
    bits_driven = 0;

    while (bits_driven < frame_bits) begin
      int bits_this_clock;
      logic [15:0] data_out;
      int bit_offset;

      if (bits_driven + bits_per_clock <= frame_bits)
        bits_this_clock = bits_per_clock;
      else
        bits_this_clock = frame_bits - bits_driven;

      // Extract bits from frame (MSB at position 559)
      bit_offset = 559 - bits_driven;
      data_out = '0;

      case (bits_this_clock)
        1:  data_out[0] = frame[bit_offset];
        4:  begin
              data_out[3] = frame[bit_offset];
              data_out[2] = frame[bit_offset-1];
              data_out[1] = frame[bit_offset-2];
              data_out[0] = frame[bit_offset-3];
            end
        8:  for (int b = 0; b < 8; b++)
              data_out[7-b] = frame[bit_offset-b];
        16: for (int b = 0; b < 16; b++)
              data_out[15-b] = frame[bit_offset-b];
        default: ; // partial clock
      endcase

      // Handle partial last clock: left-align bits in data_out
      if (bits_this_clock < bits_per_clock && bits_per_clock > 1) begin
        logic [15:0] tmp;
        tmp = '0;
        for (int b = 0; b < bits_this_clock; b++)
          tmp[bits_per_clock-1-b] = frame[bit_offset-b];
        data_out = tmp;
      end

      vif.driver_cb.pdi <= data_out;

      // Handle rxfifo backpressure for burst writes
      if (item.opcode == SPI_AHB_WR_BURST && bits_driven >= 48) begin
        while (vif.driver_cb.rxfifo_full === 1'b1) begin
          vif.driver_cb.pdi <= '0;
          @(vif.driver_cb);
        end
      end

      @(vif.driver_cb);
      bits_driven += bits_this_clock;
    end

    // Stop driving pdi
    vif.driver_cb.pdi <= '0;

    // --- Handle Response ---
    if (!item.frame_abort) begin
      // Wait for DUT response (pdo_oe goes high then low)
      while (vif.driver_cb.pdo_oe !== 1'b1)
        @(vif.driver_cb);
      while (vif.driver_cb.pdo_oe === 1'b1)
        @(vif.driver_cb);
    end

    // Deassert pcs_n
    vif.driver_cb.pcs_n <= 1'b1;

    // Inter-transaction delay (minimum 2 cycles per spec for lane_mode sync)
    if (item.trans_delay > 0)
      repeat(item.trans_delay) @(vif.driver_cb);
    else begin
      @(vif.driver_cb);
      @(vif.driver_cb);
    end
  endtask

endclass : spi_driver

`endif // SPI_DRIVER_SV
