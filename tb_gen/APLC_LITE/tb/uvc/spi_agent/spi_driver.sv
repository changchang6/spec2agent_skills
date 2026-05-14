`ifndef SPI_DRIVER_SV
`define SPI_DRIVER_SV

class spi_driver extends uvm_driver #(spi_transaction);

    virtual spi_if vif;

    uvm_analysis_port #(spi_transaction) ap_port;
    int m_FrameCnt;

    // AI gen: LRS timing constants extracted from §4.8 timing diagrams
    // Frame start: pcs_n goes low, data appears on NEXT clock edge -> OFFSET_EDGE
    localparam int FRAME_START_OFFSET_EDGE = 1;
    // Frame end: pcs_n stays low during entire transaction (request+TA+response) -> AFTER_RESPONSE
    localparam int FRAME_END_AFTER_RESPONSE = 1;
    // Turnaround: DUT controls 1-cycle turnaround via pdo_oe_o -> TA_BY_DUT
    localparam int TA_BY_DUT = 1;
    // Burst continuity: payload beats sent continuously after header -> BURST_CONTINUOUS
    localparam bit BURST_CONTINUOUS = 1'b1;
    // Last beat padding: pad low bits with 0 when frame bits don't divide by lane width
    localparam bit LAST_BEAT_PAD_ZERO = 1'b1;
    // MSB first data transmission
    localparam bit MSB_FIRST = 1'b1;

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
        this.reset_signals();
        this.get_and_drive();
    endtask

    // AI gen: Reset all driven signals to idle state
    virtual task reset_signals();
        wait(vif.rst_n === 1'b1);
        vif.drv_cb.pcs_n <= 1'b1;
        vif.drv_cb.pdi   <= 16'b0;
        m_FrameCnt = 0;
    endtask

    virtual task get_and_drive();
        spi_transaction trans;
        forever begin
            seq_item_port.get_next_item(req);
            if(!$cast(trans, req.clone()))
                `uvm_fatal(get_type_name(), "spi_driver get trans failed!");
            `uvm_info(get_type_name(), $sformatf("Driving: %s", trans.convert2string()), UVM_HIGH)
            trans_drive(trans);
            ap_port.write(trans);
            m_FrameCnt++;
            seq_item_port.item_done();
        end
    endtask : get_and_drive

    // AI gen: Main transaction driving task
    virtual task trans_drive(spi_transaction tr);
        bit [560:0] frame_data;
        int frame_bits;

        wait(vif.rst_n === 1'b1);

        // Build frame data (MSB-first bit stream)
        build_frame(tr, frame_data, frame_bits);

        // Drive request phase
        drive_request(frame_data, frame_bits, tr);

        // Drive response collection
        drive_response(tr);

        // Release frame (pcs_n high)
        // FRAME_END_AFTER_RESPONSE: release after response collected and pdo_oe drops
        if (FRAME_END_AFTER_RESPONSE) begin
            wait(vif.pdo_oe === 1'b0);
        end
        vif.drv_cb.pcs_n <= 1'b1;
        vif.drv_cb.pdi   <= 16'b0;
        @(vif.drv_cb);
    endtask

    // AI gen: Build frame bit stream from transaction fields, MSB-first
    virtual function void build_frame(spi_transaction tr, output bit [560:0] frame_data, output int frame_bits);
        int bits;
        frame_data = '0;
        bits = 0;
        case (tr.opcode)
            `OPC_WR_CSR: begin
                // [opcode(8) | reg_addr(8) | wdata(32)]
                frame_data[560-bits-1 -: 8]  = tr.opcode;   bits += 8;
                frame_data[560-bits-1 -: 8]  = tr.reg_addr;  bits += 8;
                frame_data[560-bits-1 -: 32] = tr.wdata[0];  bits += 32;
            end
            `OPC_RD_CSR: begin
                // [opcode(8) | reg_addr(8)]
                frame_data[560-bits-1 -: 8] = tr.opcode;    bits += 8;
                frame_data[560-bits-1 -: 8] = tr.reg_addr;   bits += 8;
            end
            `OPC_AHB_WR32: begin
                // [opcode(8) | addr(32) | wdata(32)]
                frame_data[560-bits-1 -: 8]  = tr.opcode;   bits += 8;
                frame_data[560-bits-1 -: 32] = tr.addr;     bits += 32;
                frame_data[560-bits-1 -: 32] = tr.wdata[0]; bits += 32;
            end
            `OPC_AHB_RD32: begin
                // [opcode(8) | addr(32)]
                frame_data[560-bits-1 -: 8]  = tr.opcode;   bits += 8;
                frame_data[560-bits-1 -: 32] = tr.addr;     bits += 32;
            end
            `OPC_AHB_WR_BURST: begin
                // [opcode(8) | burst_len(5) | rsvd(3) | addr(32) | wdata*N(32*N)]
                frame_data[560-bits-1 -: 8]  = tr.opcode;    bits += 8;
                frame_data[560-bits-1 -: 5]  = tr.burst_len; bits += 5;
                frame_data[560-bits-1 -: 3]  = 3'b000;       bits += 3; // rsvd
                frame_data[560-bits-1 -: 32] = tr.addr;      bits += 32;
                foreach (tr.wdata[i]) begin
                    frame_data[560-bits-1 -: 32] = tr.wdata[i]; bits += 32;
                end
            end
            `OPC_AHB_RD_BURST: begin
                // [opcode(8) | burst_len(5) | rsvd(3) | addr(32)]
                frame_data[560-bits-1 -: 8]  = tr.opcode;    bits += 8;
                frame_data[560-bits-1 -: 5]  = tr.burst_len; bits += 5;
                frame_data[560-bits-1 -: 3]  = 3'b000;       bits += 3; // rsvd
                frame_data[560-bits-1 -: 32] = tr.addr;      bits += 32;
            end
            default: begin
                // Illegal opcode - just send 8-bit opcode
                frame_data[560-bits-1 -: 8] = tr.opcode; bits += 8;
            end
        endcase
        frame_bits = bits;
    endfunction

    // AI gen: Drive request phase with OFFSET_EDGE timing
    virtual task drive_request(bit [560:0] frame_data, int frame_bits, spi_transaction tr);
        int bpc;
        int total_beats;
        int bit_pos;
        int beat;
        int remaining_bits;
        int valid_bits;
        int b;
        bit [15:0] beat_data;

        bpc = tr.get_bpc();
        total_beats = (frame_bits + bpc - 1) / bpc;
        bit_pos = 0;

        // OFFSET_EDGE: drive pcs_n=0 first, data on next clock edge
        vif.drv_cb.pcs_n <= 1'b0;
        @(vif.drv_cb);

        // Drive each beat MSB-first
        for (beat = 0; beat < total_beats; beat++) begin
            remaining_bits = frame_bits - bit_pos;
            valid_bits = (remaining_bits < bpc) ? remaining_bits : bpc;

            // Extract beat data from MSB-first frame
            beat_data = 16'b0;
            for (b = 0; b < valid_bits; b++) begin
                if (frame_data[560 - bit_pos - b - 1])
                    beat_data[bpc - 1 - b] = 1'b1;
            end

            // AI gen: RXFIFO backpressure check for burst write payload
            if (tr.opcode == `OPC_AHB_WR_BURST && beat >= 3) begin
                // Check rxfifo_full before driving burst payload beats
                if (vif.rxfifo_full === 1'b1) begin
                    // Stop driving data but keep pcs_n low
                    vif.drv_cb.pdi <= 16'b0;
                    // Wait for FIFO to have space
                    wait(vif.rxfifo_full === 1'b0);
                    @(vif.drv_cb);
                end
            end

            // Drive the beat
            vif.drv_cb.pdi <= beat_data;
            bit_pos += valid_bits;
            @(vif.drv_cb);
        end

        // Clear pdi after request phase
        vif.drv_cb.pdi <= 16'b0;
    endtask

    // AI gen: Collect response after turnaround (TA_BY_DUT)
    virtual task drive_response(spi_transaction tr);
        int bpc;
        int resp_bits;
        int total_beats;
        int bit_pos;
        int beat;
        int valid_bits;
        int b;
        bit [519:0] resp_data; // max 520 bits for RD_BURSTx16
        bit [15:0] beat_data;

        resp_data = '0;
        bpc = tr.get_bpc();
        resp_bits = tr.get_response_bits();
        total_beats = (resp_bits + bpc - 1) / bpc;
        bit_pos = 0;

        // TA_BY_DUT: wait for DUT to drive pdo_oe_o (indicates response start)
        wait(vif.pdo_oe === 1'b1);

        // Collect response beats
        for (beat = 0; beat < total_beats; beat++) begin
            // AI gen: TXFIFO empty check - if empty, skip this beat
            if (vif.txfifo_empty === 1'b1) begin
                // pdo_oe stays high but data is stalled, skip
                @(vif.drv_cb);
                beat--;
                continue;
            end

            @(vif.drv_cb);
            beat_data = vif.drv_cb.pdo;

            // Store beat data MSB-first into response bit stream
            valid_bits = ((resp_bits - bit_pos) < bpc) ? (resp_bits - bit_pos) : bpc;
            for (b = 0; b < valid_bits; b++) begin
                if (beat_data[bpc - 1 - b])
                    resp_data[519 - bit_pos - b] = 1'b1;
            end
            bit_pos += valid_bits;
        end

        // Parse response data into transaction fields
        parse_response(resp_data, resp_bits, tr);
    endtask

    // AI gen: Parse response bit stream into transaction response fields
    virtual function void parse_response(bit [519:0] resp_data, int resp_bits, ref spi_transaction tr);
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

endclass : spi_driver

`endif
