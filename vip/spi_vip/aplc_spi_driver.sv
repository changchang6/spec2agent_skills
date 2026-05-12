// APLC SPI VIP Driver
// Drives the ATE (master) side of the SPI-like interface

`ifndef APLC_SPI_DRIVER_SV
`define APLC_SPI_DRIVER_SV

class aplc_spi_driver extends uvm_driver #(aplc_spi_item);

    `uvm_component_utils(aplc_spi_driver)

    virtual aplc_spi_if m_vif;
    aplc_spi_agent_config m_cfg;

    // Internal frame buffer for build_frame
    local logic [559:0] m_frame;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(aplc_spi_agent_config)::get(this, "", "agent_config", m_cfg)) begin
            `uvm_fatal("APLC_SPI_DRV", "Cannot get agent_config")
        end
        m_vif = m_cfg.get_vif();
        if (m_vif == null) begin
            `uvm_fatal("APLC_SPI_DRV", "Virtual interface is null")
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        fork
            reset_listener();
            drive_transactions();
        join
    endtask

    virtual task reset_listener();
        forever begin
            @(negedge m_vif.rst_n);
            `uvm_info("APLC_SPI_DRV", "Reset detected", UVM_MEDIUM)
            reset_signals();
            @(posedge m_vif.rst_n);
            `uvm_info("APLC_SPI_DRV", "Reset released", UVM_MEDIUM)
        end
    endtask

    virtual task reset_signals();
        m_vif.pcs_n    <= 1'b1;
        m_vif.pdi      <= '0;
        m_vif.en       <= m_cfg.default_en;
        m_vif.test_mode <= m_cfg.default_test_mode;
        m_vif.lane_mode <= m_cfg.default_lane_mode;
    endtask

    virtual task drive_transactions();
        forever begin
            seq_item_port.try_next_item(req);
            if (req != null) begin
                drive_item(req);
                seq_item_port.item_done();
            end else begin
                @(posedge m_vif.clk);
            end
        end
    endtask

    virtual task drive_item(aplc_spi_item item);
        // Pre-command delay
        repeat (item.pre_command_delay) @(posedge m_vif.clk);

        // Set configuration signals
        m_vif.en        <= item.en;
        m_vif.test_mode <= item.test_mode;
        m_vif.lane_mode <= item.lane_mode;
        @(posedge m_vif.clk);

        // Build and send request frame
        send_request(item);

        // Wait for response
        receive_response(item);

        // Post-command delay
        repeat (item.post_command_delay) @(posedge m_vif.clk);

        `uvm_info("APLC_SPI_DRV", $sformatf("Driven: %s", item.convert2string()), UVM_HIGH)
    endtask

    virtual task send_request(aplc_spi_item item);
        int unsigned  frame_len;
        int unsigned  bpc;

        frame_len = build_frame(item);
        bpc = aplc_lane_bpc(item.lane_mode);

        // Pull pcs_n low to start transaction
        m_vif.pcs_n <= 1'b0;
        @(posedge m_vif.clk);

        if (frame_len > 0) begin
            drive_frame_bits(m_frame, frame_len, bpc);
        end else begin
            // Bad opcode: drive at least the opcode byte so DUT can decode it
            m_frame[559:552] = item.opcode;
            drive_frame_bits(m_frame, 8, bpc);
            // Wait a few extra cycles for DUT processing
            repeat (4) @(posedge m_vif.clk);
        end
    endtask

    virtual function int unsigned build_frame(aplc_spi_item item);
        m_frame = '0;
        case (item.opcode)
            APLC_OPCODE_WR_CSR: begin
                m_frame[559:552] = item.opcode;
                m_frame[551:544] = item.reg_addr;
                m_frame[543:512] = item.wdata;
                return 48;
            end
            APLC_OPCODE_RD_CSR: begin
                m_frame[559:552] = item.opcode;
                m_frame[551:544] = item.reg_addr;
                return 16;
            end
            APLC_OPCODE_AHB_WR32: begin
                m_frame[559:552] = item.opcode;
                m_frame[551:520] = item.addr;
                m_frame[519:488] = item.wdata;
                return 72;
            end
            APLC_OPCODE_AHB_RD32: begin
                m_frame[559:552] = item.opcode;
                m_frame[551:520] = item.addr;
                return 40;
            end
            APLC_OPCODE_AHB_WR_BURST: begin
                m_frame[559:552] = item.opcode;
                m_frame[551:547] = item.burst_len;
                m_frame[546:544] = 3'b000;
                m_frame[543:512] = item.addr;
                for (int i = 0; i < item.burst_len; i++) begin
                    m_frame[(511 - i*32) -: 32] = item.wdata_burst[i];
                end
                return 48 + 32 * item.burst_len;
            end
            APLC_OPCODE_AHB_RD_BURST: begin
                m_frame[559:552] = item.opcode;
                m_frame[551:547] = item.burst_len;
                m_frame[546:544] = 3'b000;
                m_frame[543:512] = item.addr;
                return 48;
            end
            default: return 0;
        endcase
    endfunction

    virtual task drive_frame_bits(logic [559:0] frame, int unsigned frame_len, int unsigned bpc);
        int unsigned bits_sent = 0;
        logic [15:0] pdi_data;

        while (bits_sent < frame_len) begin
            int unsigned bits_this_cycle;
            int unsigned remaining;

            remaining = frame_len - bits_sent;
            bits_this_cycle = (remaining < bpc) ? remaining : bpc;

            // Extract MSB-first bits from frame
            pdi_data = '0;
            for (int i = 0; i < bits_this_cycle; i++) begin
                pdi_data[bpc - 1 - i] = frame[559 - bits_sent - i];
            end

            m_vif.pdi <= pdi_data;
            @(posedge m_vif.clk);
            bits_sent += bits_this_cycle;
        end

        // Clear pdi after frame is sent
        m_vif.pdi <= '0;
    endtask

    localparam int unsigned RESPONSE_TIMEOUT_CYCLES = 10000;

    virtual task receive_response(aplc_spi_item item);
        int unsigned resp_len;
        int unsigned bpc;
        logic [559:0] resp_frame;
        int unsigned  bits_received;
        int unsigned  timeout_cnt;

        // For bad opcode or other error injection, build a minimal 8-bit frame
        // The DUT should still respond with a status byte even for errors
        resp_len = 8;  // At minimum, expect 8-bit status
        bpc = aplc_lane_bpc(item.lane_mode);

        // Wait for turnaround (pdo_oe goes high) with timeout
        timeout_cnt = 0;
        while (m_vif.pdo_oe !== 1'b1 && timeout_cnt < RESPONSE_TIMEOUT_CYCLES) begin
            @(posedge m_vif.clk);
            timeout_cnt++;
        end
        if (timeout_cnt >= RESPONSE_TIMEOUT_CYCLES) begin
            `uvm_error("APLC_SPI_DRV", "Timeout waiting for DUT response (pdo_oe)")
            item.status = 8'hFF;  // Indicate timeout
            m_vif.pcs_n <= 1'b1;
            @(posedge m_vif.clk);
            return;
        end
        @(posedge m_vif.clk);

        // First, receive the 8-bit status byte
        bits_received = 0;
        resp_frame = '0;
        while (bits_received < 8) begin
            int unsigned bits_this_cycle;
            logic [15:0] pdo_data;

            bits_this_cycle = (8 - bits_received < bpc) ? (8 - bits_received) : bpc;
            pdo_data = m_vif.pdo;
            for (int i = 0; i < bits_this_cycle; i++) begin
                resp_frame[559 - bits_received - i] = pdo_data[bpc - 1 - i];
            end
            bits_received += bits_this_cycle;
            @(posedge m_vif.clk);
        end

        // Parse status
        item.status = resp_frame[559:552];

        // If status is OK and command expects read data, continue receiving
        resp_len = 0;
        if (item.status === 8'h00) begin
            case (item.opcode)
                APLC_OPCODE_RD_CSR,
                APLC_OPCODE_AHB_RD32:     resp_len = 32;
                APLC_OPCODE_AHB_RD_BURST: resp_len = 32 * item.burst_len;
                default:                  resp_len = 0;
            endcase
        end

        while (bits_received < 8 + resp_len) begin
            int unsigned bits_this_cycle;
            int unsigned remaining;
            logic [15:0] pdo_data;

            remaining = 8 + resp_len - bits_received;
            bits_this_cycle = (remaining < bpc) ? remaining : bpc;

            pdo_data = m_vif.pdo;

            for (int i = 0; i < bits_this_cycle; i++) begin
                resp_frame[559 - bits_received - i] = pdo_data[bpc - 1 - i];
            end

            bits_received += bits_this_cycle;
            @(posedge m_vif.clk);
        end

        // Parse response (rdata portion)
        parse_rdata(item, resp_frame);

        // Release pcs_n
        m_vif.pcs_n <= 1'b1;
        @(posedge m_vif.clk);
    endtask

    virtual function void parse_rdata(aplc_spi_item item, logic [559:0] resp_frame);
        case (item.opcode)
            APLC_OPCODE_RD_CSR,
            APLC_OPCODE_AHB_RD32: begin
                item.rdata = resp_frame[551:520];
            end
            APLC_OPCODE_AHB_RD_BURST: begin
                item.rdata_burst.delete();
                for (int i = 0; i < item.burst_len; i++) begin
                    item.rdata_burst.push_back(resp_frame[(551 - i*32) -: 32]);
                end
            end
            default: ;
        endcase
    endfunction

endclass

`endif
