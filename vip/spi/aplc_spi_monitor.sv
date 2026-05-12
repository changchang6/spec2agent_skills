`ifndef APLC_SPI_MONITOR_SV
`define APLC_SPI_MONITOR_SV

class aplc_spi_monitor extends uvm_monitor;
    `uvm_component_utils(aplc_spi_monitor)

    virtual aplc_spi_if m_vif;
    aplc_spi_agent_config m_cfg;

    uvm_analysis_port #(aplc_spi_mon_item) req_ap;
    uvm_analysis_port #(aplc_spi_mon_item) rsp_ap;

    local bit m_in_frame;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        req_ap = new("req_ap", this);
        rsp_ap = new("rsp_ap", this);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(aplc_spi_agent_config)::get(this, "", "cfg", m_cfg))
            `uvm_fatal("SPI_MON", "Failed to get agent config")
        m_vif = m_cfg.m_vif;
    endfunction

    virtual function logic [559:0] shift_in_beat(logic [559:0] shift_reg,
                                                   logic [15:0] beat,
                                                   int bpc);
        case (bpc)
            1:  return (shift_reg << 1)  | {558'b0, beat[0]};
            4:  return (shift_reg << 4)  | {556'b0, beat[3:0]};
            8:  return (shift_reg << 8)  | {552'b0, beat[7:0]};
            16: return (shift_reg << 16) | {544'b0, beat[15:0]};
            default: return (shift_reg << 16) | {544'b0, beat[15:0]};
        endcase
    endfunction

    virtual task run_phase(uvm_phase phase);
        wait (m_vif.rst_n === 1'b1);
        m_in_frame = 0;
        forever begin
            @(m_vif.mon_cb);
            if (!m_in_frame && m_vif.mon_cb.pcs_n === 1'b0) begin
                m_in_frame = 1;
                collect_request();
            end
        end
    endtask

    virtual task collect_request();
        aplc_spi_mon_item mon_item;
        logic [559:0] rx_shift;
        int           rx_count;
        int           bpc;
        logic [15:0]  data_beat;
        logic         abort_detected;

        mon_item = aplc_spi_mon_item::type_id::create("mon_item");
        rx_shift = '0;
        rx_count = 0;
        abort_detected = 0;
        bpc = get_bpc(aplc_lane_mode_e'(m_vif.mon_cb.lane_mode));
        mon_item.lane_mode = aplc_lane_mode_e'(m_vif.mon_cb.lane_mode);

        // Same-edge mode: first data beat on SAME clock edge as pcs_n going low
        data_beat = m_vif.mon_cb.pdi;
        rx_shift = shift_in_beat(rx_shift, data_beat, bpc);
        rx_count += bpc;

        // Collect remaining request beats
        forever begin
            @(m_vif.mon_cb);
            if (m_vif.mon_cb.pcs_n === 1'b1) begin
                if (rx_count >= 8) begin
                    abort_detected = 1;
                    mon_item.frame_abort = 1;
                    mon_item.flags = "FRAME_ABORT";
                end
                break;
            end
            if (m_vif.mon_cb.pdo_oe === 1'b1) begin
                break;
            end
            data_beat = m_vif.mon_cb.pdi;
            rx_shift = shift_in_beat(rx_shift, data_beat, bpc);
            rx_count += bpc;
        end

        // Parse request fields
        parse_request(mon_item, rx_shift, rx_count);
        mon_item.is_response = 0;

        if (abort_detected)
            `uvm_info("SPI_MON", $sformatf("FRAME_ABORT: %s", mon_item.convert2string()), UVM_LOW)
        else
            `uvm_info("SPI_MON", mon_item.convert2string(), UVM_LOW)
        req_ap.write(mon_item);

        // If not aborted, collect response
        if (!abort_detected) begin
            if (m_vif.mon_cb.pdo_oe !== 1'b1) begin
                wait (m_vif.pdo_oe === 1'b1);
                @(m_vif.mon_cb);
            end
            collect_response(mon_item);
        end

        m_in_frame = 0;
    endtask

    virtual task collect_response(aplc_spi_mon_item req_item);
        aplc_spi_mon_item rsp_item;
        logic [559:0] rx_shift;
        int           rx_count;
        int           bpc;
        logic [15:0]  data_beat;

        rsp_item = aplc_spi_mon_item::type_id::create("rsp_item");
        rsp_item.opcode      = req_item.opcode;
        rsp_item.lane_mode   = req_item.lane_mode;
        rsp_item.burst_len   = req_item.burst_len;
        rsp_item.is_response = 1;

        rx_shift = '0;
        rx_count = 0;
        bpc = get_bpc(rsp_item.lane_mode);

        while (m_vif.mon_cb.pdo_oe === 1'b1) begin
            data_beat = m_vif.mon_cb.pdo;
            rx_shift = shift_in_beat(rx_shift, data_beat, bpc);
            rx_count += bpc;
            @(m_vif.mon_cb);
        end

        parse_response(rsp_item, rx_shift, rx_count);

        print_transaction(rsp_item);
        rsp_ap.write(rsp_item);
    endtask

    virtual function void parse_request(aplc_spi_mon_item item,
                                         logic [559:0] rx_shift,
                                         int rx_count);
        logic [7:0] opcode_val;
        if (rx_count < 8) return;

        opcode_val = rx_shift[rx_count-1 -: 8];
        if (!$cast(item.opcode, opcode_val))
            item.opcode = aplc_opcode_e'(opcode_val);

        case (opcode_val)
            8'h10: begin
                if (rx_count >= 16) item.reg_addr = rx_shift[rx_count-9 -: 8];
                if (rx_count >= 48) item.wdata_q.push_back(rx_shift[rx_count-17 -: 32]);
            end
            8'h11: begin
                if (rx_count >= 16) item.reg_addr = rx_shift[rx_count-9 -: 8];
            end
            8'h20: begin
                if (rx_count >= 40) item.addr = rx_shift[rx_count-9 -: 32];
                if (rx_count >= 72) item.wdata_q.push_back(rx_shift[rx_count-41 -: 32]);
            end
            8'h21: begin
                if (rx_count >= 40) item.addr = rx_shift[rx_count-9 -: 32];
            end
            8'h22, 8'h23: begin
                if (rx_count >= 16) item.burst_len = rx_shift[rx_count-9 -: 5];
                if (rx_count >= 48) item.addr = rx_shift[rx_count-17 -: 32];
                if (opcode_val == 8'h22 && rx_count > 48) begin
                    int payload_bits = rx_count - 48;
                    int n_beats = payload_bits / 32;
                    for (int i = 0; i < n_beats; i++) begin
                        int hi = rx_count - 49 - i*32;
                        item.wdata_q.push_back(rx_shift[hi -: 32]);
                    end
                end
            end
        endcase
    endfunction

    virtual function void parse_response(aplc_spi_mon_item item,
                                          logic [559:0] rx_shift,
                                          int rx_count);
        if (rx_count < 8) return;

        item.status = rx_shift[rx_count-1 -: 8];

        case (item.opcode)
            APLC_OP_RD_CSR, APLC_OP_AHB_RD32: begin
                if (rx_count >= 40)
                    item.rdata_q.push_back(rx_shift[rx_count-9 -: 32]);
            end
            APLC_OP_AHB_RD_BURST: begin
                int n_beats = (rx_count - 8) / 32;
                for (int i = 0; i < n_beats; i++) begin
                    int hi = rx_count - 9 - i*32;
                    item.rdata_q.push_back(rx_shift[hi -: 32]);
                end
            end
        endcase
    endfunction

    virtual function void print_transaction(aplc_spi_mon_item item);
        `uvm_info("SPI_MON", item.convert2string(), UVM_LOW)
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
