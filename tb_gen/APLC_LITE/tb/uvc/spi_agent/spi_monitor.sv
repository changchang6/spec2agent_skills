`ifndef SPI_MONITOR_SV
`define SPI_MONITOR_SV

class spi_monitor extends uvm_monitor;
    virtual spi_if vif;
    uvm_analysis_port #(spi_transaction) ap_port;

    // AI gen: LRS timing constants - must match driver
    localparam int FRAME_START_OFFSET_EDGE = 1;
    localparam int FRAME_END_AFTER_RESPONSE = 1;
    localparam int TA_BY_DUT = 1;
    localparam bit BURST_CONTINUOUS = 1'b1;
    localparam bit MSB_FIRST = 1'b1;

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

    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        forever begin
            spi_transaction tr;
            tr = spi_transaction::type_id::create("tr");
            monitor_transaction(tr);
            if (tr.opcode != 8'h00 || tr.status != 8'h00 || tr.frame_abort) begin
                print_transaction(tr);
                ap_port.write(tr);
            end
        end
    endtask

    // AI gen: Main monitor task - detect and collect complete transaction
    virtual task monitor_transaction(ref spi_transaction tr);
        // Wait for pcs_n to go low (frame start)
        wait(vif.pcs_n === 1'b0);
        @(vif.mon_cb);

        // Collect control signals at frame start
        tr.en        = vif.mon_cb.en;
        tr.test_mode = vif.mon_cb.test_mode;
        tr.lane_mode = vif.mon_cb.lane_mode;

        // OFFSET_EDGE: data appears on next clock edge after pcs_n goes low
        if (FRAME_START_OFFSET_EDGE) begin
            @(vif.mon_cb); // Advance 1 cycle - data starts here
        end

        // Collect request phase
        collect_request(tr);

        // If frame abort detected, skip response collection
        if (tr.frame_abort) return;

        // Wait for response via pdo_oe (TA_BY_DUT)
        collect_response(tr);

        // Wait for transaction end (pcs_n goes high or pdo_oe drops)
        wait(vif.pcs_n === 1'b1 || vif.pdo_oe === 1'b0);
    endtask

    // AI gen: Collect request phase data from pdi
    virtual task collect_request(ref spi_transaction tr);
        bit [560:0] frame_data;
        int bit_pos;
        int bpc;
        bit [7:0] opcode_latched;
        bit [4:0] burst_len_latched;
        int expected_bits;
        bit opcode_done;
        bit burst_header_done;
        bit [15:0] beat_data;
        int valid_bits;
        int b;

        frame_data = '0;
        bit_pos = 0;
        opcode_done = 0;
        burst_header_done = 0;
        expected_bits = 0;

        bpc = get_bpc(tr.lane_mode);

        forever begin
            // Check for frame abort: pcs_n goes high before request complete
            if (vif.pcs_n === 1'b1) begin
                if (opcode_done && bit_pos < expected_bits) begin
                    tr.frame_abort = 1'b1;
                    tr.status = `STS_FRAME_ERR;
                    `uvm_info(get_type_name(), "FRAME_ABORT: pcs_n released before request complete", UVM_LOW)
                end
                return;
            end

            beat_data = vif.mon_cb.pdi;
            valid_bits = bpc;

            // Store beat data MSB-first
            for (b = 0; b < valid_bits; b++) begin
                if (beat_data[bpc - 1 - b])
                    frame_data[560 - bit_pos - 1] = 1'b1;
                else
                    frame_data[560 - bit_pos - 1] = 1'b0;
                bit_pos++;
            end

            // Latch opcode after 8 bits
            if (!opcode_done && bit_pos >= 8) begin
                opcode_latched = frame_data[560-:8];
                tr.opcode = opcode_latched;
                opcode_done = 1;
                // Set initial expected bits based on opcode
                case (opcode_latched)
                    `OPC_WR_CSR:       expected_bits = `WR_CSR_FRAME_BITS;
                    `OPC_RD_CSR:       expected_bits = `RD_CSR_FRAME_BITS;
                    `OPC_AHB_WR32:     expected_bits = `AHB_WR32_FRAME_BITS;
                    `OPC_AHB_RD32:     expected_bits = `AHB_RD32_FRAME_BITS;
                    `OPC_AHB_WR_BURST,
                    `OPC_AHB_RD_BURST: expected_bits = `BURST_HEADER_BITS;
                    default:           expected_bits = 8;
                endcase
            end

            // Revise expected_bits after 16 bits for burst commands
            if (opcode_done && !burst_header_done && bit_pos >= 16) begin
                burst_len_latched = frame_data[560-8-1 -: 5]; // bits [7:3] of 2nd byte
                tr.burst_len = burst_len_latched;
                burst_header_done = 1;
                if (opcode_latched == `OPC_AHB_WR_BURST) begin
                    expected_bits = `BURST_HEADER_BITS + 32 * burst_len_latched;
                end
            end

            // Check if frame is complete
            if (opcode_done && bit_pos >= expected_bits) begin
                parse_request(frame_data, bit_pos, tr);
                return;
            end

            @(vif.mon_cb);
        end
    endtask

    // AI gen: Collect response phase data from pdo
    virtual task collect_response(ref spi_transaction tr);
        bit [519:0] resp_data;
        int bit_pos;
        int bpc;
        int resp_bits;
        int total_beats;
        int beat;
        int remaining;
        int valid_bits;
        int b;
        bit [15:0] beat_data;
        bit [15:0] prev_beat_data;

        resp_data = '0;
        bit_pos = 0;

        bpc = get_bpc(tr.lane_mode);
        resp_bits = tr.get_response_bits();
        total_beats = (resp_bits + bpc - 1) / bpc;

        // Wait for DUT to drive pdo_oe (turnaround handled by DUT)
        wait(vif.pdo_oe === 1'b1);
        @(vif.mon_cb);

        for (beat = 0; beat < total_beats; beat++) begin
            // AI gen: TXFIFO empty check - if txfifo_empty, data is stalled
            if (vif.txfifo_empty === 1'b1) begin
                // Skip this beat - pdo_oe stays high but data holds previous value
                prev_beat_data = vif.mon_cb.pdo;
                @(vif.mon_cb);
                beat--;
                continue;
            end

            beat_data = vif.mon_cb.pdo;
            prev_beat_data = beat_data;

            // Store beat data MSB-first
            remaining = resp_bits - bit_pos;
            valid_bits = (remaining < bpc) ? remaining : bpc;
            for (b = 0; b < valid_bits; b++) begin
                if (beat_data[bpc - 1 - b])
                    resp_data[519 - bit_pos - b] = 1'b1;
                else
                    resp_data[519 - bit_pos - b] = 1'b0;
            end
            bit_pos += valid_bits;

            if (bit_pos >= resp_bits) break;

            // Check for premature pcs_n release during response
            if (vif.pcs_n === 1'b1) begin
                `uvm_info(get_type_name(), "FRAME_ABORT: pcs_n released during response", UVM_LOW)
                tr.frame_abort = 1'b1;
                return;
            end

            @(vif.mon_cb);
        end

        // Parse response
        parse_response_data(resp_data, resp_bits, tr);
    endtask

    // AI gen: Parse request bit stream into transaction fields
    virtual function void parse_request(bit [560:0] frame_data, int frame_bits, ref spi_transaction tr);
        int bit_pos;
        int i;
        bit_pos = 0;
        tr.opcode = frame_data[560-bit_pos-1 -: 8];
        bit_pos += 8;

        case (tr.opcode)
            `OPC_WR_CSR: begin
                tr.reg_addr = frame_data[560-bit_pos-1 -: 8];  bit_pos += 8;
                tr.wdata = new[1];
                tr.wdata[0] = frame_data[560-bit_pos-1 -: 32]; bit_pos += 32;
                tr.is_csr = 1'b1; tr.is_write = 1'b1;
            end
            `OPC_RD_CSR: begin
                tr.reg_addr = frame_data[560-bit_pos-1 -: 8];  bit_pos += 8;
                tr.is_csr = 1'b1; tr.is_write = 1'b0;
            end
            `OPC_AHB_WR32: begin
                tr.addr = frame_data[560-bit_pos-1 -: 32];    bit_pos += 32;
                tr.wdata = new[1];
                tr.wdata[0] = frame_data[560-bit_pos-1 -: 32]; bit_pos += 32;
                tr.is_csr = 1'b0; tr.is_write = 1'b1; tr.is_burst = 1'b0;
            end
            `OPC_AHB_RD32: begin
                tr.addr = frame_data[560-bit_pos-1 -: 32];    bit_pos += 32;
                tr.is_csr = 1'b0; tr.is_write = 1'b0; tr.is_burst = 1'b0;
            end
            `OPC_AHB_WR_BURST: begin
                tr.burst_len = frame_data[560-bit_pos-1 -: 5]; bit_pos += 5;
                bit_pos += 3; // rsvd
                tr.addr = frame_data[560-bit_pos-1 -: 32];    bit_pos += 32;
                tr.wdata = new[tr.burst_len];
                for (i = 0; i < tr.burst_len; i++) begin
                    tr.wdata[i] = frame_data[560-bit_pos-1 -: 32]; bit_pos += 32;
                end
                tr.is_csr = 1'b0; tr.is_write = 1'b1; tr.is_burst = 1'b1;
            end
            `OPC_AHB_RD_BURST: begin
                tr.burst_len = frame_data[560-bit_pos-1 -: 5]; bit_pos += 5;
                bit_pos += 3; // rsvd
                tr.addr = frame_data[560-bit_pos-1 -: 32];    bit_pos += 32;
                tr.is_csr = 1'b0; tr.is_write = 1'b0; tr.is_burst = 1'b1;
            end
            default: begin
                // Unknown opcode
            end
        endcase
    endfunction

    // AI gen: Parse response bit stream into transaction response fields
    virtual function void parse_response_data(bit [519:0] resp_data, int resp_bits, ref spi_transaction tr);
        int bit_pos;
        int i;
        bit_pos = 0;
        tr.status = resp_data[519-bit_pos-1 -: 8];
        bit_pos += 8;

        case (tr.opcode)
            `OPC_RD_CSR, `OPC_AHB_RD32: begin
                tr.rdata = new[1];
                tr.rdata[0] = resp_data[519-bit_pos-1 -: 32];
            end
            `OPC_AHB_RD_BURST: begin
                tr.rdata = new[tr.burst_len];
                for (i = 0; i < tr.burst_len; i++) begin
                    tr.rdata[i] = resp_data[519-bit_pos-1 -: 32];
                    bit_pos += 32;
                end
            end
            default: begin
                // Write commands: only status byte
            end
        endcase
    endfunction

    // AI gen: Print transaction at UVM_LOW for default visibility
    virtual function void print_transaction(spi_transaction tr);
        string flags;
        flags = "";
        if (tr.frame_abort) flags = " [FRAME_ABORT]";
        `uvm_info(get_type_name(), $sformatf("Monitored: %s%s", tr.convert2string(), flags), UVM_LOW)
    endfunction

    // AI gen: Helper - get bits per clock from lane_mode
    virtual function int get_bpc(bit [1:0] lm);
        case (lm)
            `LANE_MODE_1BIT:  return 1;
            `LANE_MODE_4BIT:  return 4;
            `LANE_MODE_8BIT:  return 8;
            `LANE_MODE_16BIT: return 16;
            default:          return 16;
        endcase
    endfunction

endclass : spi_monitor

`endif
