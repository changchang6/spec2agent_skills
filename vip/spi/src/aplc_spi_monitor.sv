// APLC SPI Monitor
// Monitors the SPI-like interface and collects request/response transactions
`ifndef APLC_SPI_MONITOR_SV
`define APLC_SPI_MONITOR_SV

class aplc_spi_monitor extends uvm_monitor;

    virtual aplc_spi_if vif;

    uvm_analysis_port #(aplc_spi_mon_item) m_req_port;
    uvm_analysis_port #(aplc_spi_mon_item) m_rsp_port;

    // Timing constants (extracted from LRS §4.8)
    // Frame start: same-edge mode - pcs_n and first data appear on same clock edge
    // LRS §4.8.1~4.8.5: pcs_n_i goes low and pdi_i first data appears simultaneously
    localparam bit FRAME_START_OFFSET_EDGE = 1'b0; // same-edge mode
    // TXFIFO empty stall exists
    localparam bit HAS_TXFIFO_EMPTY = 1'b1;

    `uvm_component_utils(aplc_spi_monitor)

    function new(string name = "aplc_spi_monitor", uvm_component parent = null);
        super.new(name, parent);
        m_req_port = new("m_req_port", this);
        m_rsp_port = new("m_rsp_port", this);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual aplc_spi_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("APLC_SPI_MON", "Virtual interface not set")
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        forever begin
            wait(vif.rst_n === 1'b1);
            fork
                monitor_transaction();
            join_none
            @(negedge vif.rst_n);
            disable fork;
        end
    endtask

    virtual task monitor_transaction();
        aplc_spi_mon_item mon_txn;
        logic [79:0]  req_buffer;
        logic [519:0] rsp_buffer;
        logic [15:0]  rx_shift;
        int rx_count;
        int bpc;
        aplc_lane_mode_e txn_lane_mode;

        forever begin
            // Wait for pcs_n to go low (transaction start)
            @(vif.mon_cb);
            if (vif.mon_cb.pcs_n !== 1'b0) continue;

            // Capture lane mode at transaction start
            txn_lane_mode = aplc_lane_mode_e'(vif.mon_cb.lane_mode);
            bpc = get_bpc(txn_lane_mode);

            // Create monitor item
            mon_txn = aplc_spi_mon_item::type_id::create("mon_txn");
            mon_txn.lane_mode = txn_lane_mode;
            mon_txn.direction = aplc_spi_mon_item::MON_REQ;

            // ---- Request Phase ----
            // Same-edge mode: pcs_n and first data appear on same clock edge
            // Do NOT advance clock - capture first data on the same edge where pcs_n is low
            if (!FRAME_START_OFFSET_EDGE) begin
                // Same-edge: first data is already on the bus at the same time as pcs_n=0
                // No need to advance clock before sampling
            end

            rx_count = 0;
            req_buffer = '0;

            // Collect request data until pcs_n goes high or pdo_oe goes high
            while (vif.mon_cb.pcs_n === 1'b0 && vif.mon_cb.pdo_oe === 1'b0) begin
                // Check lane_mode stability
                if (aplc_lane_mode_e'(vif.mon_cb.lane_mode) !== txn_lane_mode) begin
                    mon_txn.lane_changed = 1'b1;
                    `uvm_warning("APLC_SPI_MON", "Lane mode changed during transaction")
                end

                // Sample pdi data
                case (bpc)
                    1:  rx_shift = {15'b0, vif.mon_cb.pdi[0]};
                    4:  rx_shift = {12'b0, vif.mon_cb.pdi[3:0]};
                    8:  rx_shift = {8'b0, vif.mon_cb.pdi[7:0]};
                    16: rx_shift = vif.mon_cb.pdi;
                    default: rx_shift = vif.mon_cb.pdi;
                endcase

                // Shift into request buffer (MSB-first)
                for (int b = 0; b < bpc && rx_count < 80; b++) begin
                    req_buffer[79 - rx_count] = rx_shift[bpc - 1 - b];
                    rx_count++;
                end

                @(vif.mon_cb);
            end

            // Check for frame abort (pcs_n high while pdo_oe still low)
            if (vif.mon_cb.pcs_n === 1'b1 && vif.mon_cb.pdo_oe === 1'b0) begin
                mon_txn.frame_abort = 1'b1;
                `uvm_info("APLC_SPI_MON", "Frame abort detected", UVM_LOW)
            end

            // Parse request fields from buffer
            parse_request(mon_txn, req_buffer, rx_count);

            // Send request item
            m_req_port.write(mon_txn);
            print_transaction(mon_txn);

            // ---- Wait for Response Phase ----
            // Wait for pdo_oe to go high (response starts)
            // DUT controls turnaround, so we wait for pdo_oe
            if (vif.mon_cb.pdo_oe !== 1'b1) begin
                // Wait for pdo_oe to assert
                wait(vif.pdo_oe === 1'b1);
                @(vif.mon_cb);
            end

            // ---- Response Phase ----
            rsp_buffer = '0;
            rx_count = 0;

            while (vif.mon_cb.pdo_oe === 1'b1) begin
                // Handle txfifo_empty stall for burst read response
                if (HAS_TXFIFO_EMPTY && vif.mon_cb.txfifo_empty === 1'b1) begin
                    // Data not valid, skip this beat
                    @(vif.mon_cb);
                    continue;
                end

                // Sample pdo data
                case (bpc)
                    1:  rx_shift = {15'b0, vif.mon_cb.pdo[0]};
                    4:  rx_shift = {12'b0, vif.mon_cb.pdo[3:0]};
                    8:  rx_shift = {8'b0, vif.mon_cb.pdo[7:0]};
                    16: rx_shift = vif.mon_cb.pdo;
                    default: rx_shift = vif.mon_cb.pdo;
                endcase

                // Shift into response buffer (MSB-first)
                for (int b = 0; b < bpc && rx_count < 520; b++) begin
                    rsp_buffer[519 - rx_count] = rx_shift[bpc - 1 - b];
                    rx_count++;
                end

                @(vif.mon_cb);
            end

            // Parse response
            parse_response(mon_txn, rsp_buffer, rx_count);

            // Send response item
            mon_txn.direction = aplc_spi_mon_item::MON_RSP;
            m_rsp_port.write(mon_txn);
            print_transaction(mon_txn);
        end
    endtask

    // Get bits per clock from lane mode
    virtual function int get_bpc(aplc_lane_mode_e lane);
        case (lane)
            APLC_LANE_1BIT:  return 1;
            APLC_LANE_4BIT:  return 4;
            APLC_LANE_8BIT:  return 8;
            APLC_LANE_16BIT: return 16;
            default:         return 16;
        endcase
    endfunction

    // Parse request from bit buffer
    virtual function void parse_request(aplc_spi_mon_item mon_txn,
                                         logic [79:0] req_buffer,
                                         int rx_count);
        logic [7:0] opcode_byte;

        if (rx_count < 8) return;

        // Extract opcode (first 8 bits, MSB-first)
        opcode_byte = '0;
        for (int i = 0; i < 8; i++)
            opcode_byte[7 - i] = req_buffer[79 - i];

        if (opcode_byte inside {8'h10, 8'h11, 8'h20, 8'h21, 8'h22, 8'h23})
            mon_txn.opcode = aplc_opcode_e'(opcode_byte);
        else
            mon_txn.opcode = opcode_byte; // store raw value

        // Parse opcode-specific fields
        case (opcode_byte)
            8'h10: begin // WR_CSR
                for (int i = 0; i < 8; i++)
                    mon_txn.reg_addr[7 - i] = req_buffer[79 - 8 - i];
                for (int i = 0; i < 32; i++)
                    mon_txn.wdata[0][31 - i] = req_buffer[79 - 16 - i];
            end
            8'h11: begin // RD_CSR
                for (int i = 0; i < 8; i++)
                    mon_txn.reg_addr[7 - i] = req_buffer[79 - 8 - i];
            end
            8'h20: begin // AHB_WR32
                for (int i = 0; i < 32; i++)
                    mon_txn.addr[31 - i] = req_buffer[79 - 8 - i];
                mon_txn.wdata = new[1];
                for (int i = 0; i < 32; i++)
                    mon_txn.wdata[0][31 - i] = req_buffer[79 - 40 - i];
            end
            8'h21: begin // AHB_RD32
                for (int i = 0; i < 32; i++)
                    mon_txn.addr[31 - i] = req_buffer[79 - 8 - i];
            end
            8'h22, 8'h23: begin // Burst commands
                for (int i = 0; i < 5; i++)
                    mon_txn.burst_len[4 - i] = req_buffer[79 - 8 - i];
                for (int i = 0; i < 32; i++)
                    mon_txn.addr[31 - i] = req_buffer[79 - 16 - i];
            end
            default: ;
        endcase
    endfunction

    // Parse response from bit buffer
    virtual function void parse_response(aplc_spi_mon_item mon_txn,
                                          logic [519:0] rsp_buffer,
                                          int rx_count);
        logic [7:0] status_byte;
        int data_bits;
        int data_beats;

        if (rx_count < 8) return;

        // Extract status byte (first 8 bits of response, MSB-first)
        status_byte = '0;
        for (int i = 0; i < 8; i++)
            status_byte[7 - i] = rsp_buffer[519 - i];
        mon_txn.status = status_byte;

        // Parse read data based on opcode
        if (mon_txn.opcode inside {APLC_OP_RD_CSR, APLC_OP_AHB_RD32} && rx_count >= 40) begin
            mon_txn.rdata = new[1];
            for (int i = 0; i < 32; i++)
                mon_txn.rdata[0][31 - i] = rsp_buffer[519 - 8 - i];
        end else if (mon_txn.opcode == APLC_OP_AHB_RD_BURST && rx_count > 8) begin
            data_bits = rx_count - 8;
            data_beats = data_bits / 32;
            mon_txn.rdata = new[data_beats];
            for (int w = 0; w < data_beats; w++) begin
                for (int i = 0; i < 32; i++)
                    mon_txn.rdata[w][31 - i] = rsp_buffer[519 - 8 - w*32 - i];
            end
        end
    endfunction

    // Print transaction
    virtual function void print_transaction(aplc_spi_mon_item mon_txn);
        `uvm_info("APLC_SPI_MON", mon_txn.convert2string(), UVM_LOW)
    endfunction

endclass

`endif
