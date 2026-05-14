`ifndef SPI_MONITOR_SV
`define SPI_MONITOR_SV

class spi_monitor extends uvm_monitor;
    virtual spi_if vif;
    uvm_analysis_port #(spi_transaction) ap_port;

    // Timing constants (must match driver)
    localparam spi_frame_start_e FRAME_START_MODE = FRAME_START_OFFSET_EDGE;
    localparam spi_ta_mode_e     TA_MODE          = TA_BY_DUT;
    localparam bit               MSB_FIRST        = 1'b1;

    `uvm_component_utils(spi_monitor)

    function new(string name = "spi_monitor", uvm_component parent);
        super.new(name, parent);
        ap_port = new("ap_port", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual spi_if)::get(this, "", "spi_vif", vif))
            `uvm_fatal("NOVIF", "Virtual interface not set")
    endfunction

    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        wait(vif.rst_n === 1'b1);
        forever begin
            spi_transaction tr;
            tr = spi_transaction::type_id::create("tr");
            collect_transaction(tr);
            if(tr.opcode != spi_opcode_e'('x)) begin
                print_transaction(tr);
                ap_port.write(tr);
            end
        end
    endtask

    virtual task collect_transaction(spi_transaction tr);
        logic [`MAX_FRAME_BITS-1:0] req_shift;
        logic [`MAX_FRAME_BITS-1:0] resp_shift;
        int bits_collected;
        int lane_w;
        logic [15:0] data_beat;
        logic [7:0] opcode_latched;
        int expected_bits;
        bit frame_abort_detected;

        // Wait for transaction start: pcs_n falling edge
        wait(vif.pcs_n === 1'b0);

        // OFFSET_EDGE mode: pcs_n went low, data appears on NEXT clock edge
        // So we advance one clock cycle before collecting first data beat
        @(vif.mon_cb);

        // Get lane width from current lane_mode
        lane_w = get_lane_width(spi_lane_mode_e'(vif.mon_cb.lane_mode));
        tr.lane_mode = spi_lane_mode_e'(vif.mon_cb.lane_mode);

        // Phase 1: Collect request header (at least 8 bits to get opcode)
        req_shift = '0;
        bits_collected = 0;
        frame_abort_detected = 0;

        // Collect at least opcode (8 bits)
        while(bits_collected < 8) begin
            // Check frame abort: pcs_n released during request
            if(vif.mon_cb.pcs_n === 1'b1) begin
                frame_abort_detected = (bits_collected >= 8);
                if(!frame_abort_detected) begin
                    // Less than 8 bits received, silent reset
                    return;
                end
                break;
            end

            data_beat = vif.mon_cb.pdi;
            shift_in_data(req_shift, bits_collected, data_beat, lane_w);
            @(vif.mon_cb);
        end

        if(frame_abort_detected) begin
            tr.frame_abort = 1;
            tr.status = STS_FRAME_ERR;
            // Wait for pcs_n to go high
            wait(vif.mon_cb.pcs_n === 1'b1);
            return;
        end

        // Extract opcode (MSB-first, located at bits_collected-1 down to bits_collected-8)
        opcode_latched = req_shift[bits_collected - 1 -: 8];
        tr.opcode = spi_opcode_e'(opcode_latched);

        // Determine expected frame length based on opcode
        expected_bits = get_expected_request_bits(tr.opcode, req_shift, bits_collected, lane_w);

        // Continue collecting remaining request bits
        while(bits_collected < expected_bits) begin
            if(vif.mon_cb.pcs_n === 1'b1) begin
                // Frame abort: pcs_n released before all bits received
                tr.frame_abort = 1;
                tr.status = STS_FRAME_ERR;
                return;
            end

            data_beat = vif.mon_cb.pdi;
            shift_in_data(req_shift, bits_collected, data_beat, lane_w);
            @(vif.mon_cb);
        end

        // Parse request from shift register
        parse_request(req_shift, bits_collected, tr);

        // For burst write, collect payload beats
        if(tr.opcode == OPC_AHB_WR_BURST) begin
            collect_burst_payload(tr, lane_w);
        end

        // Phase 2: Wait for response
        // DUT controls turnaround via pdo_oe signal
        // Wait for pdo_oe to go high (DUT indicates it's driving response)
        wait(vif.pdo_oe === 1'b1);
        @(vif.mon_cb);

        // Phase 3: Collect response
        resp_shift = '0;
        bits_collected = 0;
        expected_bits = tr.get_response_bits();
        if(expected_bits == 0) expected_bits = 8;

        while(bits_collected < expected_bits) begin
            // Handle TXFIFO empty stall: pdo_oe active but txfifo_empty
            // Data holds previous value, skip this beat
            if(vif.mon_cb.txfifo_empty === 1'b1) begin
                @(vif.mon_cb);
                continue;
            end

            data_beat = vif.mon_cb.pdo;
            shift_in_data(resp_shift, bits_collected, data_beat, lane_w);
            @(vif.mon_cb);

            // Check if pcs_n released during response
            if(vif.mon_cb.pcs_n === 1'b1) begin
                // TX abort - response truncated
                break;
            end
        end

        // Parse response
        parse_response(resp_shift, bits_collected, tr);

        // Wait for transaction end (pcs_n high and pdo_oe low)
        wait(vif.pcs_n === 1'b1 && vif.pdo_oe === 1'b0);
    endtask

    virtual task collect_burst_payload(spi_transaction tr, int lane_w);
        logic [15:0] data_beat;
        int payload_bits;
        int bits_collected;
        logic [31:0] word_shift;
        int word_bits;
        int word_count;

        payload_bits = 32 * tr.burst_len;
        bits_collected = 0;
        word_count = 0;
        word_bits = 0;

        while(bits_collected < payload_bits) begin
            if(vif.mon_cb.pcs_n === 1'b1) begin
                tr.frame_abort = 1;
                tr.status = STS_FRAME_ERR;
                return;
            end

            data_beat = vif.mon_cb.pdi;
            for(int i = 0; i < lane_w && bits_collected < payload_bits; i++) begin
                word_shift = word_shift << 1;
                word_shift[0] = data_beat[lane_w - 1 - i];
                word_bits++;
                bits_collected++;

                if(word_bits == 32) begin
                    word_count++;
                    word_bits = 0;
                end
            end
            @(vif.mon_cb);
        end
    endtask

    virtual function void shift_in_data(
        ref logic [`MAX_FRAME_BITS-1:0] shift_reg,
        ref int bits_collected,
        input logic [15:0] data,
        input int lane_w
    );
        for(int i = 0; i < lane_w; i++) begin
            shift_reg = shift_reg << 1;
            shift_reg[0] = data[lane_w - 1 - i];
            bits_collected++;
        end
    endfunction

    virtual function int get_expected_request_bits(
        spi_opcode_e opcode,
        logic [`MAX_FRAME_BITS-1:0] req_shift,
        int bits_collected,
        int lane_w
    );
        logic [4:0] burst_len_val;
        case(opcode)
            OPC_WR_CSR:     return 48;
            OPC_RD_CSR:     return 16;
            OPC_AHB_WR32:   return 72;
            OPC_AHB_RD32:   return 40;
            OPC_AHB_WR_BURST: begin
                if(bits_collected >= 16) begin
                    burst_len_val = req_shift[bits_collected - 9 -: 5];
                    return 48 + 32 * burst_len_val;
                end
                return 48;
            end
            OPC_AHB_RD_BURST: return 48;
            default:        return 8;
        endcase
    endfunction

    virtual function void parse_request(
        ref logic [`MAX_FRAME_BITS-1:0] req_shift,
        input int bits_collected,
        ref spi_transaction tr
    );
        case(tr.opcode)
            OPC_WR_CSR: begin
                tr.reg_addr = req_shift[bits_collected - 9 -: 8];
                tr.wdata    = req_shift[bits_collected - 17 -: 32];
            end
            OPC_RD_CSR: begin
                tr.reg_addr = req_shift[bits_collected - 9 -: 8];
            end
            OPC_AHB_WR32: begin
                tr.addr  = req_shift[bits_collected - 9 -: 32];
                tr.wdata = req_shift[bits_collected - 41 -: 32];
            end
            OPC_AHB_RD32: begin
                tr.addr = req_shift[bits_collected - 9 -: 32];
            end
            OPC_AHB_WR_BURST,
            OPC_AHB_RD_BURST: begin
                tr.burst_len = req_shift[bits_collected - 9 -: 5];
                tr.addr      = req_shift[bits_collected - 17 -: 32];
            end
        endcase
    endfunction

    virtual function void parse_response(
        ref logic [`MAX_FRAME_BITS-1:0] resp_shift,
        input int bits_collected,
        ref spi_transaction tr
    );
        if(bits_collected < 8) return;

        // First 8 bits are status
        tr.status = spi_status_e'(resp_shift[bits_collected - 1 -: 8]);

        if(tr.has_rdata() && bits_collected > 8) begin
            int rdata_bits;
            int num_words;
            logic [`DATA_WIDTH-1:0] rdata_word;

            rdata_bits = bits_collected - 8;
            num_words = rdata_bits / 32;
            tr.rdata = new[num_words];

            for(int w = 0; w < num_words; w++) begin
                rdata_word = resp_shift[(bits_collected - 8 - w*32 - 1) -: 32];
                tr.rdata[w] = rdata_word;
            end
        end
    endfunction

    virtual function void print_transaction(spi_transaction tr);
        string msg;
        msg = $sformatf("[SPI_MON] opcode=%s lane_mode=%0d",
            tr.opcode.name(), tr.lane_mode);

        if(tr.frame_abort)
            msg = {msg, " FRAME_ABORT"};

        case(tr.opcode)
            OPC_WR_CSR: begin
                msg = {msg, $sformatf(" reg_addr=0x%02h wdata=0x%08h", tr.reg_addr, tr.wdata)};
            end
            OPC_RD_CSR: begin
                msg = {msg, $sformatf(" reg_addr=0x%02h", tr.reg_addr)};
            end
            OPC_AHB_WR32: begin
                msg = {msg, $sformatf(" addr=0x%08h wdata=0x%08h", tr.addr, tr.wdata)};
            end
            OPC_AHB_RD32: begin
                msg = {msg, $sformatf(" addr=0x%08h", tr.addr)};
            end
            OPC_AHB_WR_BURST,
            OPC_AHB_RD_BURST: begin
                msg = {msg, $sformatf(" burst_len=%0d addr=0x%08h", tr.burst_len, tr.addr)};
            end
        endcase

        msg = {msg, $sformatf(" status=%s", tr.status.name())};

        if(tr.has_rdata() && tr.rdata.size() > 0) begin
            for(int i = 0; i < tr.rdata.size(); i++) begin
                msg = {msg, $sformatf(" rdata[%0d]=0x%08h", i, tr.rdata[i])};
            end
        end

        `uvm_info("SPI_MON", msg, UVM_LOW)
    endfunction

    virtual function int get_lane_width(spi_lane_mode_e mode);
        case(mode)
            LANE_MODE_1BIT:  return 1;
            LANE_MODE_4BIT:  return 4;
            LANE_MODE_8BIT:  return 8;
            LANE_MODE_16BIT: return 16;
            default:         return 16;
        endcase
    endfunction

endclass : spi_monitor

`endif
