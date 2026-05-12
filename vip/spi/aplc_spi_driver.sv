`ifndef APLC_SPI_DRIVER_SV
`define APLC_SPI_DRIVER_SV

class aplc_spi_driver extends uvm_driver #(aplc_spi_item);
    `uvm_component_utils(aplc_spi_driver)

    virtual aplc_spi_if m_vif;
    aplc_spi_agent_config m_cfg;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(aplc_spi_agent_config)::get(this, "", "cfg", m_cfg))
            `uvm_fatal("SPI_DRV", "Failed to get agent config")
        m_vif = m_cfg.m_vif;
    endfunction

    virtual task run_phase(uvm_phase phase);
        wait (m_vif.rst_n === 1'b1);
        init_signals();
        forever begin
            seq_item_port.try_next_item(req);
            if (req == null) begin
                @(m_vif.drv_cb);
                continue;
            end
            drive_transaction(req);
            seq_item_port.item_done();
        end
    endtask

    virtual task init_signals();
        @(m_vif.drv_cb);
        m_vif.drv_cb.pcs_n <= 1'b1;
        m_vif.drv_cb.pdi   <= '0;
        @(m_vif.drv_cb);
    endtask

    virtual task drive_transaction(aplc_spi_item item);
        logic [559:0] shift_data;
        int           total_bits;
        int           orig_bits;
        int           bpc;
        logic [15:0]  data_beat;

        bpc = get_bpc(item.lane_mode);
        shift_data = build_frame(item);
        total_bits = item.get_request_bits();
        orig_bits  = total_bits;

        // Same-edge drive: pcs_n=0 and first data beat on the same clock edge
        data_beat = get_beat(shift_data, total_bits, bpc);
        m_vif.drv_cb.pcs_n <= 1'b0;
        m_vif.drv_cb.pdi   <= data_beat;
        total_bits -= bpc;

        // Drive remaining beats
        while (total_bits > 0) begin
            shift_data = shift_data << bpc;
            data_beat = get_beat(shift_data, orig_bits, bpc);
            @(m_vif.drv_cb);
            m_vif.drv_cb.pdi <= data_beat;
            total_bits -= bpc;
        end

        // Stop driving pdi, keep pcs_n low
        @(m_vif.drv_cb);
        m_vif.drv_cb.pdi <= '0;

        // Wait for DUT response
        wait (m_vif.pdo_oe === 1'b1);
        @(m_vif.drv_cb);

        // Collect response
        collect_response(item);

        // Wait for response to complete, then release pcs_n
        wait (m_vif.pdo_oe === 1'b0);
        @(m_vif.drv_cb);
        m_vif.drv_cb.pcs_n <= 1'b1;
        // Wait for pcs_n=1 to take effect and DUT to return to IDLE
        @(m_vif.drv_cb);
        @(m_vif.drv_cb);
    endtask

    // Extract top bpc bits from shift_data using only shifts (no variable part-select)
    virtual function logic [15:0] get_beat(input logic [559:0] data,
                                            input int total_bits,
                                            input int bpc);
        logic [559:0] masked;
        logic [15:0]  beat;
        beat = '0;
        if (total_bits >= bpc) begin
            // Extract top bpc bits
            masked = data >> (total_bits - bpc);
            case (bpc)
                1:  beat[0]  = masked[0];
                4:  beat[3:0]  = masked[3:0];
                8:  beat[7:0]  = masked[7:0];
                16: beat[15:0] = masked[15:0];
            endcase
        end else if (total_bits > 0) begin
            // Partial beat - data is already in low bits after shift
            masked = data;
            case (bpc)
                1: begin
                    beat[0] = masked[0];
                end
                4: begin
                    beat[3]   = masked[total_bits-1];
                    beat[2]   = (total_bits > 1) ? masked[total_bits-2] : 1'b0;
                    beat[1]   = (total_bits > 2) ? masked[total_bits-3] : 1'b0;
                    beat[0]   = (total_bits > 3) ? masked[total_bits-4] : 1'b0;
                end
                8: begin
                    for (int i = 0; i < 8; i++) begin
                        if (i < total_bits)
                            beat[7-i] = masked[total_bits-1-i];
                        else
                            beat[7-i] = 1'b0;
                    end
                end
                16: begin
                    for (int i = 0; i < 16; i++) begin
                        if (i < total_bits)
                            beat[15-i] = masked[total_bits-1-i];
                        else
                            beat[15-i] = 1'b0;
                    end
                end
            endcase
        end
        return beat;
    endfunction

    virtual task collect_response(aplc_spi_item item);
        logic [559:0] resp_shift;
        int           resp_bits;
        int           resp_count;
        int           bpc;
        logic [15:0]  data_beat;

        bpc = get_bpc(item.lane_mode);
        resp_bits = item.get_response_bits();
        resp_shift = '0;
        resp_count = 0;

        while (resp_count < resp_bits && m_vif.drv_cb.pdo_oe === 1'b1) begin
            data_beat = m_vif.drv_cb.pdo;
            case (bpc)
                1:  resp_shift = (resp_shift << 1)  | {558'b0, data_beat[0]};
                4:  resp_shift = (resp_shift << 4)  | {556'b0, data_beat[3:0]};
                8:  resp_shift = (resp_shift << 8)  | {552'b0, data_beat[7:0]};
                16: resp_shift = (resp_shift << 16) | {544'b0, data_beat[15:0]};
            endcase
            resp_count += bpc;
            if (resp_count < resp_bits && m_vif.drv_cb.pdo_oe === 1'b1)
                @(m_vif.drv_cb);
        end

        // Parse status byte (always first 8 bits of response)
        item.status = resp_shift[resp_count-1 -: 8];

        // Parse read data based on opcode
        case (item.opcode)
            APLC_OP_RD_CSR,
            APLC_OP_AHB_RD32: begin
                if (resp_count >= 40)
                    item.rdata = resp_shift[resp_count-9 -: 32];
            end
            APLC_OP_AHB_RD_BURST: begin
                int n_beats = (resp_count - 8) / 32;
                for (int i = 0; i < n_beats; i++) begin
                    int hi = resp_count - 9 - i*32;
                    item.rdata_q.push_back(resp_shift[hi -: 32]);
                end
            end
        endcase
    endtask

    virtual function logic [559:0] build_frame(aplc_spi_item item);
        logic [559:0] frame;
        frame = '0;
        case (item.opcode)
            APLC_OP_WR_CSR: begin
                frame = {471'b0, item.opcode, item.reg_addr, item.wdata};
            end
            APLC_OP_RD_CSR: begin
                frame = {543'b0, item.opcode, item.reg_addr};
            end
            APLC_OP_AHB_WR32: begin
                frame = {487'b0, item.opcode, item.addr, item.wdata};
            end
            APLC_OP_AHB_RD32: begin
                frame = {519'b0, item.opcode, item.addr};
            end
            APLC_OP_AHB_WR_BURST,
            APLC_OP_AHB_RD_BURST: begin
                frame = {511'b0, item.opcode, item.burst_len, 3'b000, item.addr};
                if (item.opcode == APLC_OP_AHB_WR_BURST && item.wdata_q.size() > 0) begin
                    foreach (item.wdata_q[i]) begin
                        frame = (frame << 32) | {527'b0, item.wdata_q[i]};
                    end
                end
            end
        endcase
        return frame;
    endfunction

    virtual function int get_bpc(aplc_lane_mode_e mode);
        case (mode)
            APLC_LANE_1BIT:  return 1;
            APLC_LANE_4BIT:  return 4;
            APLC_LANE_8BIT:  return 8;
            APLC_LANE_16BIT: return 16;
            default:         return 16;
        endcase
    endfunction

endclass

`endif
