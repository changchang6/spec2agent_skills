// APLC SPI VIP Monitor
// Observes the SPI-like interface and publishes monitor items

`ifndef APLC_SPI_MONITOR_SV
`define APLC_SPI_MONITOR_SV

class aplc_spi_monitor extends uvm_monitor;

    `uvm_component_utils(aplc_spi_monitor)

    uvm_analysis_port #(aplc_spi_mon_item) out_port;

    virtual aplc_spi_if m_vif;
    aplc_spi_agent_config m_cfg;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        out_port = new("out_port", this);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(aplc_spi_agent_config)::get(this, "", "agent_config", m_cfg)) begin
            `uvm_fatal("APLC_SPI_MON", "Cannot get agent_config")
        end
        m_vif = m_cfg.get_vif();
        if (m_vif == null) begin
            `uvm_fatal("APLC_SPI_MON", "Virtual interface is null")
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        fork
            reset_listener();
            collect_transactions();
        join
    endtask

    virtual task reset_listener();
        forever begin
            @(negedge m_vif.rst_n);
            `uvm_info("APLC_SPI_MON", "Reset detected", UVM_MEDIUM)
            @(posedge m_vif.rst_n);
            `uvm_info("APLC_SPI_MON", "Reset released", UVM_MEDIUM)
        end
    endtask

    virtual task collect_transactions();
        forever begin
            aplc_spi_mon_item mon_item;

            // Wait for transaction start (pcs_n falling edge)
            wait (m_vif.rst_n === 1'b1 && m_vif.pcs_n === 1'b0);
            mon_item = aplc_spi_mon_item::type_id::create("mon_item");

            // Capture request
            collect_request(mon_item);

            // Capture response
            collect_response(mon_item);

            // Publish
            out_port.write(mon_item);

            `uvm_info("APLC_SPI_MON", $sformatf("Observed: %s", mon_item.convert2string()), UVM_HIGH)
        end
    endtask

    virtual task collect_request(aplc_spi_mon_item item);
        logic [559:0] rx_shift;
        int unsigned  rx_count;
        int unsigned  bpc;
        logic [7:0]   opcode_latched;
        int unsigned  expected_bits;
        logic [1:0]   lane_at_start;
        bit           lane_changed;

        rx_shift = '0;
        rx_count = 0;
        lane_changed = 0;
        lane_at_start = m_vif.lane_mode;
        item.observed_lane_mode = aplc_lane_mode_e'(lane_at_start);
        item.req_start_time = $time;

        // Wait 1 cycle after pcs_n falls (setup)
        @(posedge m_vif.clk);

        // Phase 1: Receive until opcode latch (first 8 bits)
        bpc = aplc_lane_bpc(aplc_lane_mode_e'(m_vif.lane_mode));

        while (rx_count < 8 && m_vif.pcs_n === 1'b0) begin
            bpc = aplc_lane_bpc(aplc_lane_mode_e'(m_vif.lane_mode));
            capture_bits(rx_shift, rx_count, bpc);
            if (m_vif.lane_mode !== lane_at_start) lane_changed = 1;
            @(posedge m_vif.clk);
        end

        if (m_vif.pcs_n !== 1'b0) begin
            // Frame abort before opcode latched - silent reset
            item.has_frame_abort = 1;
            item.frame_complete = 0;
            return;
        end

        // Latch opcode
        opcode_latched = rx_shift[559:552];
        item.opcode = aplc_opcode_e'(opcode_latched);

        // Determine expected frame length
        expected_bits = aplc_opcode_frame_len(item.opcode, 5'd0);

        // If Burst command, need to decode burst_len from bits [551:547]
        if (item.opcode inside {APLC_OPCODE_AHB_WR_BURST, APLC_OPCODE_AHB_RD_BURST}) begin
            // Continue receiving until we have at least 16 bits (opcode + burst_len field)
            while (rx_count < 16 && m_vif.pcs_n === 1'b0) begin
                bpc = aplc_lane_bpc(aplc_lane_mode_e'(m_vif.lane_mode));
                capture_bits(rx_shift, rx_count, bpc);
                if (m_vif.lane_mode !== lane_at_start) lane_changed = 1;
                @(posedge m_vif.clk);
            end
            if (m_vif.pcs_n !== 1'b0) begin
                item.has_frame_abort = 1;
                item.frame_complete = 0;
                return;
            end
            item.burst_len = rx_shift[551:547];
            expected_bits = aplc_opcode_frame_len(item.opcode, item.burst_len);
        end

        // Phase 2: Continue receiving until expected_bits or pcs_n rises
        while (rx_count < expected_bits && m_vif.pcs_n === 1'b0) begin
            bpc = aplc_lane_bpc(aplc_lane_mode_e'(m_vif.lane_mode));
            capture_bits(rx_shift, rx_count, bpc);
            if (m_vif.lane_mode !== lane_at_start) lane_changed = 1;
            @(posedge m_vif.clk);
        end

        item.lane_mode_stable = !lane_changed;
        item.rx_cycles = (rx_count + bpc - 1) / bpc;

        // Check for frame abort
        if (m_vif.pcs_n !== 1'b0 && rx_count < expected_bits) begin
            item.has_frame_abort = 1;
            item.frame_complete = 0;
            item.req_end_time = $time;
            return;
        end

        item.frame_complete = 1;
        item.req_end_time = $time;

        // Parse request fields from frame
        parse_request_frame(item, rx_shift);
    endtask

    virtual task capture_bits(ref logic [559:0] rx_shift, ref int unsigned rx_count, input int unsigned bpc);
        logic [15:0] pdo_data;
        pdo_data = m_vif.pdi;
        for (int i = 0; i < bpc; i++) begin
            rx_shift[559 - rx_count] = pdo_data[bpc - 1 - i];
            rx_count++;
        end
    endtask

    virtual function void parse_request_frame(aplc_spi_mon_item item, logic [559:0] frame);
        case (item.opcode)
            APLC_OPCODE_WR_CSR: begin
                item.reg_addr = frame[551:544];
                item.wdata    = frame[543:512];
            end
            APLC_OPCODE_RD_CSR: begin
                item.reg_addr = frame[551:544];
            end
            APLC_OPCODE_AHB_WR32: begin
                item.addr  = frame[551:520];
                item.wdata = frame[519:488];
            end
            APLC_OPCODE_AHB_RD32: begin
                item.addr = frame[551:520];
            end
            APLC_OPCODE_AHB_WR_BURST: begin
                item.addr = frame[543:512];
                item.wdata_burst.delete();
                for (int i = 0; i < item.burst_len; i++) begin
                    item.wdata_burst.push_back(frame[(511 - i*32) -: 32]);
                end
            end
            APLC_OPCODE_AHB_RD_BURST: begin
                item.addr = frame[543:512];
            end
            default: ;
        endcase
    endfunction

    virtual task collect_response(aplc_spi_mon_item item);
        int unsigned resp_len;
        int unsigned bpc;
        logic [559:0] resp_frame;
        int unsigned  bits_received;

        if (item.has_frame_abort) return;

        // Wait for turnaround (pdo_oe goes high)
        wait (m_vif.pdo_oe === 1'b1 || m_vif.pcs_n === 1'b1);
        if (m_vif.pcs_n === 1'b1) begin
            item.turnaround_ok = 0;
            return;
        end
        item.turnaround_ok = 1;
        item.resp_start_time = $time;
        @(posedge m_vif.clk);

        // Determine response length
        resp_len = aplc_response_len(item.opcode, item.burst_len);
        bpc = aplc_lane_bpc(aplc_lane_mode_e'(m_vif.lane_mode));

        // Receive response bits
        bits_received = 0;
        resp_frame = '0;

        while (bits_received < resp_len && m_vif.pdo_oe === 1'b1) begin
            logic [15:0] pdo_data;
            int unsigned bits_this_cycle;
            int unsigned remaining;

            remaining = resp_len - bits_received;
            bits_this_cycle = (remaining < bpc) ? remaining : bpc;

            pdo_data = m_vif.pdo;
            for (int i = 0; i < bits_this_cycle; i++) begin
                resp_frame[559 - bits_received - i] = pdo_data[bpc - 1 - i];
            end

            bits_received += bits_this_cycle;
            @(posedge m_vif.clk);
        end

        item.tx_cycles = (bits_received + bpc - 1) / bpc;
        item.resp_end_time = $time;

        // Parse response
        item.status = resp_frame[559:552];
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
    endtask

endclass

`endif
