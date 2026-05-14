`ifndef SPI_DRIVER_SV
`define SPI_DRIVER_SV

class spi_driver extends uvm_driver #(spi_transaction);

    virtual spi_if vif;

    uvm_analysis_port #(spi_transaction) ap_port;
    int m_FrameCnt;

    // Timing constants extracted from LRS §4.8
    // Frame start: offset-edge mode (pcs_n goes low first, data valid next cycle)
    localparam spi_frame_start_e FRAME_START_MODE = FRAME_START_OFFSET_EDGE;
    // Frame end: response-after-release (pcs_n stays low until entire transaction completes)
    localparam spi_frame_end_e   FRAME_END_MODE   = FRAME_END_AFTER_RESPONSE;
    // Turnaround: DUT controls (pdo_oe indicates direction switch)
    localparam spi_ta_mode_e     TA_MODE          = TA_BY_DUT;
    // Burst continuity: payload beats are continuous with header, no gaps
    localparam bit               BURST_CONTINUOUS  = 1'b1;
    // MSB-first data transmission
    localparam bit               MSB_FIRST         = 1'b1;

    `uvm_component_utils(spi_driver)

    function new(string name, uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual spi_if)::get(this, "", "spi_vif", vif))
            `uvm_fatal("NOVIF", "Virtual interface not set")
        ap_port = new("ap_port", this);
    endfunction

    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        this.get_and_drive();
    endtask

    virtual task get_and_drive();
        wait(vif.rst_n === 1'b1);
        m_FrameCnt = 0;
        forever begin
            spi_transaction trans;
            seq_item_port.get_next_item(req);
            if(!$cast(trans, req.clone()))
                `uvm_fatal(get_type_name(), "spi_driver get trans failed!")
            trans_drive(trans);
            ap_port.write(trans);
            m_FrameCnt++;
            seq_item_port.item_done();
        end
    endtask : get_and_drive

    virtual task trans_drive(spi_transaction tr);
        // Wait for idle state (pcs_n should be high = idle)
        wait(vif.pcs_n === 1'b1);
        @(vif.drv_cb);

        // Drive frame start based on FRAME_START_MODE
        drive_request(tr);

        // Wait for DUT response
        if(!tr.frame_abort) begin
            collect_response(tr);
        end

        // Release frame based on FRAME_END_MODE
        // FRAME_END_AFTER_RESPONSE: pcs_n stays low until response is collected
        // Then pcs_n goes high to end the transaction
        release_frame();
    endtask

    virtual task drive_request(spi_transaction tr);
        logic [`MAX_FRAME_BITS-1:0] frame_data;
        int total_bits;
        int lane_w;

        lane_w = get_lane_width(tr.lane_mode);
        total_bits = tr.get_request_bits();

        // Build request frame MSB-first
        frame_data = '0;
        case(tr.opcode)
            OPC_WR_CSR: begin
                frame_data[47:40] = tr.opcode;
                frame_data[39:32] = tr.reg_addr;
                frame_data[31:0]  = tr.wdata;
            end
            OPC_RD_CSR: begin
                frame_data[15:8]  = tr.opcode;
                frame_data[7:0]   = tr.reg_addr;
            end
            OPC_AHB_WR32: begin
                frame_data[71:64] = tr.opcode;
                frame_data[63:32] = tr.addr;
                frame_data[31:0]  = tr.wdata;
            end
            OPC_AHB_RD32: begin
                frame_data[39:32] = tr.opcode;
                frame_data[31:0]  = tr.addr;
            end
            OPC_AHB_WR_BURST: begin
                frame_data[47:40] = tr.opcode;
                frame_data[39:35] = tr.burst_len;
                frame_data[34:32] = 3'b000;
                frame_data[31:0]  = tr.addr;
                // Burst payload will be driven after header
            end
            OPC_AHB_RD_BURST: begin
                frame_data[47:40] = tr.opcode;
                frame_data[39:35] = tr.burst_len;
                frame_data[34:32] = 3'b000;
                frame_data[31:0]  = tr.addr;
            end
        endcase

        // Drive control signals
        vif.drv_cb.en        <= 1'b1;
        vif.drv_cb.test_mode <= 1'b1;

        // OFFSET_EDGE mode: drive pcs_n low first
        vif.drv_cb.pcs_n <= 1'b0;
        @(vif.drv_cb);

        // Now drive data beats
        drive_data_beats(frame_data, total_bits, lane_w, tr);

        // Drive burst write payload if needed
        if(tr.opcode == OPC_AHB_WR_BURST && !tr.frame_abort) begin
            drive_burst_payload(tr, lane_w);
        end
    endtask

    virtual task drive_data_beats(
        ref logic [`MAX_FRAME_BITS-1:0] frame_data,
        input int total_bits,
        input int lane_w,
        input spi_transaction tr
    );
        int bits_driven;
        int beat_idx;
        logic [15:0] data_beat;

        bits_driven = 0;
        beat_idx = total_bits - 1; // MSB first

        while(bits_driven < total_bits) begin
            // Check RXFIFO backpressure for burst payload phase
            if(vif.rxfifo_full === 1'b1) begin
                // Stop driving data but keep pcs_n low
                vif.drv_cb.pdi <= '0;
                @(vif.drv_cb);
                continue;
            end

            // Extract lane_w bits from frame_data, MSB-first
            data_beat = '0;
            for(int i = 0; i < lane_w; i++) begin
                if(bits_driven + i < total_bits) begin
                    data_beat[lane_w - 1 - i] = frame_data[beat_idx - i];
                end
            end

            vif.drv_cb.pdi <= data_beat;
            bits_driven += lane_w;
            beat_idx -= lane_w;
            @(vif.drv_cb);

            // Check for frame abort (pcs_n released early)
            if(vif.pcs_n === 1'b1) begin
                tr.frame_abort = 1;
                return;
            end
        end
    endtask

    virtual task drive_burst_payload(spi_transaction tr, int lane_w);
        logic [`DATA_WIDTH-1:0] wdata_beat;
        logic [15:0] data_beat;
        int bits_in_word;
        int payload_words;

        // Burst payload: each 32-bit wdata word needs ceil(32/lane_w) beats
        // BURST_CONTINUOUS=1: payload follows header with no gap
        payload_words = tr.burst_len;

        for(int w = 0; w < payload_words; w++) begin
            // Each payload word is 32 bits, sourced from wdata_queue
            if(tr.wdata_queue.size() > w)
                wdata_beat = tr.wdata_queue[w];
            else
                wdata_beat = tr.wdata;

            bits_in_word = 0;
            for(int b = 0; b < 32; b += lane_w) begin
                // Check RXFIFO backpressure
                if(vif.rxfifo_full === 1'b1) begin
                    vif.drv_cb.pdi <= '0;
                    @(vif.drv_cb);
                    continue;
                end

                data_beat = '0;
                for(int i = 0; i < lane_w && (bits_in_word + i) < 32; i++) begin
                    data_beat[lane_w - 1 - i] = wdata_beat[31 - bits_in_word - i];
                end

                vif.drv_cb.pdi <= data_beat;
                bits_in_word += lane_w;
                @(vif.drv_cb);

                if(vif.pcs_n === 1'b1) begin
                    tr.frame_abort = 1;
                    return;
                end
            end
        end
    endtask

    virtual task collect_response(spi_transaction tr);
        logic [15:0] pdo_data;
        logic [`MAX_FRAME_BITS-1:0] resp_shift;
        int resp_bits;
        int bits_collected;
        int lane_w;
        int resp_total_bits;

        lane_w = get_lane_width(tr.lane_mode);
        resp_total_bits = tr.get_response_bits();
        if(resp_total_bits == 0) resp_total_bits = 8;

        // Stop driving pdi - bus is released for DUT to drive
        vif.drv_cb.pdi <= '0;

        // Wait for DUT output enable (pdo_oe) - DUT controls turnaround
        // Also check for frame abort (pcs_n released early, DUT may not drive response)
        fork
            begin : wait_pdo_oe
                wait(vif.pdo_oe === 1'b1);
            end
            begin : wait_pcs_n_high
                wait(vif.pcs_n === 1'b1);
            end
        join_any
        disable fork;

        // If pcs_n went high before pdo_oe, this is a frame abort scenario
        if(vif.pcs_n === 1'b1 && vif.pdo_oe === 1'b0) begin
            tr.status = STS_FRAME_ERR;
            return;
        end

        @(vif.mon_cb);

        // Collect response data
        resp_shift = '0;
        bits_collected = 0;

        while(bits_collected < resp_total_bits) begin
            // Check TXFIFO empty stall - if pdo_oe active but txfifo_empty, skip this beat
            if(vif.txfifo_empty === 1'b1) begin
                @(vif.mon_cb);
                continue;
            end

            pdo_data = vif.mon_cb.pdo;

            // Shift in MSB-first
            for(int i = 0; i < lane_w && bits_collected < resp_total_bits; i++) begin
                resp_shift = resp_shift << 1;
                resp_shift[0] = pdo_data[lane_w - 1 - i];
                bits_collected++;
            end

            @(vif.mon_cb);

            // Check for early pcs_n release during response
            if(vif.pcs_n === 1'b1) begin
                break;
            end
        end

        // Parse response
        parse_response(resp_shift, bits_collected, tr);
    endtask

    virtual task parse_response(
        ref logic [`MAX_FRAME_BITS-1:0] resp_shift,
        input int bits_collected,
        ref spi_transaction tr
    );
        // First 8 bits are always status
        tr.status = spi_status_e'(resp_shift[bits_collected - 1 -: 8]);

        if(tr.has_rdata() && bits_collected > 8) begin
            int rdata_bits = bits_collected - 8;
            int num_words;
            logic [`DATA_WIDTH-1:0] rdata_word;

            num_words = rdata_bits / 32;
            tr.rdata = new[num_words];

            for(int w = 0; w < num_words; w++) begin
                rdata_word = resp_shift[(bits_collected - 8 - w*32 - 1) -: 32];
                tr.rdata[w] = rdata_word;
            end
        end
    endtask

    virtual task release_frame();
        // FRAME_END_AFTER_RESPONSE: wait for pdo_oe to drop, then release pcs_n
        if(vif.pdo_oe === 1'b1) begin
            wait(vif.pdo_oe === 1'b0);
        end
        @(vif.drv_cb);
        vif.drv_cb.pcs_n <= 1'b1;
        vif.drv_cb.pdi   <= '0;
        @(vif.drv_cb);
    endtask

    virtual function int get_lane_width(spi_lane_mode_e mode);
        case(mode)
            LANE_MODE_1BIT:  return 1;
            LANE_MODE_4BIT:  return 4;
            LANE_MODE_8BIT:  return 8;
            LANE_MODE_16BIT: return 16;
            default:         return 16;
        endcase
    endfunction

endclass : spi_driver

`endif
