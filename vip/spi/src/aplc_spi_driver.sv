// APLC SPI Master Driver
// Drives the SPI-like interface as ATE host (master)
`ifndef APLC_SPI_DRIVER_SV
`define APLC_SPI_DRIVER_SV

class aplc_spi_driver extends uvm_driver #(aplc_spi_item);

    virtual aplc_spi_if vif;

    // Timing constants (extracted from LRS §4.8)
    // Frame start: same-edge mode - pcs_n and first data beat appear on same clock edge
    // LRS §4.8.1~4.8.5: pcs_n_i goes low and pdi_i first data appears simultaneously
    localparam bit FRAME_START_OFFSET_EDGE = 1'b0; // same-edge mode
    // Frame end: release pcs_n after response complete
    localparam bit FRAME_END_AFTER_RESPONSE = 1'b1;
    // Turnaround: DUT controls turnaround
    localparam bit TA_BY_DUT = 1'b1;
    // Burst: payload continuous with header
    localparam bit BURST_CONTINUOUS = 1'b1;
    // RXFIFO backpressure exists
    localparam bit HAS_RXFIFO_FULL = 1'b1;
    // TXFIFO empty stall exists
    localparam bit HAS_TXFIFO_EMPTY = 1'b1;

    `uvm_component_utils(aplc_spi_driver)

    function new(string name = "aplc_spi_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual aplc_spi_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("APLC_SPI_DRV", "Virtual interface not set")
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        fork
            reset_and_idle();
            drive_txn();
        join
    endtask

    // Reset handling and idle signal driving
    virtual task reset_and_idle();
        forever begin
            @(negedge vif.rst_n);
            drive_idle();
            @(posedge vif.rst_n);
        end
    endtask

    // Main driver loop
    virtual task drive_txn();
        forever begin
            aplc_spi_item req;
            // Wait for reset to be released
            wait(vif.rst_n === 1'b1);
            seq_item_port.try_next_item(req);
            if (req == null) begin
                @(vif.drv_cb);
                continue;
            end
            drive_transaction(req);
            seq_item_port.item_done();
        end
    endtask

    // Drive idle state on interface
    virtual task drive_idle();
        vif.pcs_n   <= 1'b1;
        vif.pdi     <= '0;
        vif.en      <= 1'b1;
        vif.test_mode <= 1'b1;
    endtask

    // Main transaction driving
    virtual task drive_transaction(aplc_spi_item req);
        logic bit_queue[$];
        int bpc;
        int total_bits;
        int num_beats;

        // Set lane mode, en, test_mode before transaction
        vif.drv_cb.lane_mode <= req.lane_mode;
        vif.drv_cb.en        <= 1'b1;
        vif.drv_cb.test_mode <= 1'b1;

        // Get bits per clock
        bpc = req.get_bpc();

        // Build bit stream for request
        req.get_request_bits_stream(bit_queue);
        total_bits = bit_queue.size();

        // Pad bit queue to align with lane width
        num_beats = (total_bits + bpc - 1) / bpc;
        while (bit_queue.size() < num_beats * bpc)
            bit_queue.push_back(1'b0); // pad with 0

        // Phase 1: Drive pcs_n low and first data beat simultaneously (same-edge mode)
        // LRS §4.8: pcs_n and first pdi data appear on the same clock edge
        // Prepare first data beat
        begin
            logic [15:0] first_beat;
            first_beat = '0;
            for (int b = 0; b < bpc && b < bit_queue.size(); b++)
                first_beat[bpc - 1 - b] = bit_queue[b]; // MSB-first

            // Drive pcs_n and first data in the same clocking block event
            case (bpc)
                1:  vif.drv_cb.pdi <= {15'b0, first_beat[0]};
                4:  vif.drv_cb.pdi <= {12'b0, first_beat[3:0]};
                8:  vif.drv_cb.pdi <= {8'b0, first_beat[7:0]};
                16: vif.drv_cb.pdi <= first_beat[15:0];
                default: vif.drv_cb.pdi <= first_beat;
            endcase
            vif.drv_cb.pcs_n <= 1'b0;
        end
        @(vif.drv_cb);

        // Phase 2: Drive remaining request data beats
        drive_request_data(req, bit_queue, bpc, num_beats);

        // Phase 3: Wait for response
        wait_for_response(req, bpc);

        // Phase 4: Release pcs_n after response complete
        if (FRAME_END_AFTER_RESPONSE) begin
            // Wait for pdo_oe to drop after response
            wait(vif.pdo_oe === 1'b0);
            @(vif.drv_cb);
        end
        vif.drv_cb.pcs_n <= 1'b1;
        vif.drv_cb.pdi   <= '0;
        @(vif.drv_cb);
    endtask

    // Drive remaining request data beats (starting from beat 1)
    virtual task drive_request_data(aplc_spi_item req,
                                     ref logic bit_queue[$],
                                     input int bpc,
                                     input int num_beats);
        logic [15:0] data_beat;
        int idx;

        for (int beat = 1; beat < num_beats; beat++) begin
            // Check rxfifo_full for backpressure (burst write)
            if (HAS_RXFIFO_FULL && req.opcode == APLC_OP_AHB_WR_BURST) begin
                // Wait while FIFO is full
                while (vif.rxfifo_full === 1'b1) begin
                    vif.drv_cb.pdi <= vif.drv_cb.pdi; // hold last value
                    @(vif.drv_cb);
                end
            end

            // Assemble data beat from bit queue
            data_beat = '0;
            for (int b = 0; b < bpc && (beat * bpc + b) < bit_queue.size(); b++) begin
                idx = beat * bpc + b;
                data_beat[bpc - 1 - b] = bit_queue[idx]; // MSB-first
            end

            // Drive data on pdi (mask unused lanes)
            case (bpc)
                1:  vif.drv_cb.pdi <= {15'b0, data_beat[0]};
                4:  vif.drv_cb.pdi <= {12'b0, data_beat[3:0]};
                8:  vif.drv_cb.pdi <= {8'b0, data_beat[7:0]};
                16: vif.drv_cb.pdi <= data_beat[15:0];
                default: vif.drv_cb.pdi <= data_beat;
            endcase

            // Check for frame abort injection
            if (req.frame_abort && beat == num_beats / 2) begin
                vif.drv_cb.pcs_n <= 1'b1;
                return;
            end

            @(vif.drv_cb);
        end
    endtask

    // Wait for DUT response and collect data
    virtual task wait_for_response(aplc_spi_item req, input int bpc);
        logic [15:0] rx_shift;
        logic [519:0] resp_buffer; // max 520 bits for burst read x16
        int rx_count;
        int resp_bits;
        int resp_beats;

        // Wait for DUT to drive response (pdo_oe goes high)
        // Use wait on raw signal, not clocking block
        wait(vif.pdo_oe === 1'b1);

        // Now sync to clock edge and start collecting
        resp_bits = req.get_response_bits();
        resp_beats = (resp_bits + bpc - 1) / bpc;

        rx_count = 0;
        resp_buffer = '0;

        for (int beat = 0; beat < resp_beats; beat++) begin
            // Handle txfifo_empty stall
            if (HAS_TXFIFO_EMPTY && req.opcode == APLC_OP_AHB_RD_BURST) begin
                while (vif.txfifo_empty === 1'b1) begin
                    // Skip this beat - data is not valid
                    @(vif.mon_cb);
                end
            end

            @(vif.mon_cb);

            // Sample pdo data
            case (bpc)
                1:  rx_shift = {15'b0, vif.mon_cb.pdo[0]};
                4:  rx_shift = {12'b0, vif.mon_cb.pdo[3:0]};
                8:  rx_shift = {8'b0, vif.mon_cb.pdo[7:0]};
                16: rx_shift = vif.mon_cb.pdo;
                default: rx_shift = vif.mon_cb.pdo;
            endcase

            // Shift into response buffer (MSB-first)
            for (int b = 0; b < bpc; b++) begin
                if (rx_count < 520) begin
                    resp_buffer[resp_bits - 1 - rx_count] = rx_shift[bpc - 1 - b];
                    rx_count++;
                end
            end
        end

        // Parse response
        parse_response(req, resp_buffer, rx_count);
    endtask

    // Parse collected response bits into transaction fields
    virtual function void parse_response(aplc_spi_item req,
                                          logic [519:0] resp_buffer,
                                          int rx_count);
        logic [7:0] status_byte;
        int data_beats;

        // First 8 bits = status
        status_byte = '0;
        for (int i = 0; i < 8 && i < rx_count; i++)
            status_byte[7 - i] = resp_buffer[rx_count - 1 - i];

        req.status = status_byte;

        // Parse read data if applicable
        if (req.opcode inside {APLC_OP_RD_CSR, APLC_OP_AHB_RD32}) begin
            if (rx_count >= 40) begin
                req.rdata = new[1];
                for (int i = 0; i < 32; i++)
                    req.rdata[0][31 - i] = resp_buffer[rx_count - 1 - 8 - i];
            end
        end else if (req.opcode == APLC_OP_AHB_RD_BURST) begin
            data_beats = (rx_count - 8) / 32;
            req.rdata = new[data_beats];
            for (int w = 0; w < data_beats; w++) begin
                for (int i = 0; i < 32; i++)
                    req.rdata[w][31 - i] = resp_buffer[rx_count - 1 - 8 - w*32 - i];
            end
        end
    endfunction

endclass

`endif
