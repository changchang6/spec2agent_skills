`ifndef APLC_SPI_DRIVER_SV
`define APLC_SPI_DRIVER_SV

class aplc_spi_driver extends uvm_driver #(aplc_spi_item);

    `uvm_component_utils(aplc_spi_driver)

    uvm_analysis_port #(aplc_spi_item) output_port;

    protected aplc_spi_vif_t        m_vif;
    protected aplc_spi_agent_config m_config;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        output_port = new("output_port", this);
        if (!uvm_config_db #(aplc_spi_agent_config)::get(this, "", "aplc_spi_agent_config", m_config)) begin
            `uvm_fatal(get_id(), "Cannot get agent config")
        end
        m_vif = m_config.get_vif();
        if (m_vif == null) begin
            `uvm_fatal(get_id(), "Virtual interface is null")
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        wait (m_vif.rst_n === 1'b1);
        @(m_vif.drv_cb);
        m_vif.drv_cb.pcs_n <= 1'b1;
        m_vif.drv_cb.pdi   <= '0;
        drive_transactions();
    endtask

    virtual task drive_transactions();
        forever begin
            aplc_spi_item item;
            seq_item_port.get_next_item(item);
            drive_transaction(item);
            output_port.write(item);
            seq_item_port.item_done();
        end
    endtask

    virtual task drive_transaction(aplc_spi_item item);
        bit [79:0]  frame_data;
        int         frame_bits;
        bit [560:0] rx_data;
        int         rx_count;
        int         expected_rx_bits;
        int         bpc;

        bpc = item.get_bpc();

        frame_data = build_request_frame(item, frame_bits);

        m_vif.drv_cb.pcs_n <= 1'b0;
        m_vif.drv_cb.pdi   <= '0;
        @(m_vif.drv_cb);

        drive_frame(frame_data, frame_bits, bpc);

        if (item.opcode == APLC_SPI_AHB_WR_BURST) begin
            drive_burst_write_payload(item, bpc);
        end

        // Keep pcs_n=0 during response phase (DUT responds while pcs_n is low)
        m_vif.drv_cb.pdi   <= '0;

        collect_response(item, bpc);

        // Deassert pcs_n after response is complete
        m_vif.drv_cb.pcs_n <= 1'b1;
        m_vif.drv_cb.pdi   <= '0;
        @(m_vif.drv_cb);
    endtask

    virtual function bit [79:0] build_request_frame(aplc_spi_item item, output int frame_bits);
        bit [79:0] data;
        data = '0;

        if (item.inject_error) begin
            case (item.opcode)
                APLC_SPI_WR_CSR: begin
                    data[79:72] = item.error_opcode;
                    data[71:64] = item.error_reg_addr;
                    data[63:32] = item.wdata.size() > 0 ? item.wdata[0] : 32'h0;
                    frame_bits = 48;
                end
                APLC_SPI_RD_CSR: begin
                    data[79:72] = item.error_opcode;
                    data[71:64] = item.error_reg_addr;
                    frame_bits = 16;
                end
                APLC_SPI_AHB_WR32: begin
                    data[79:72] = item.error_opcode;
                    data[71:40] = item.error_addr;
                    data[39:8]  = item.wdata.size() > 0 ? item.wdata[0] : 32'h0;
                    frame_bits = 72;
                end
                APLC_SPI_AHB_RD32: begin
                    data[79:72] = item.error_opcode;
                    data[71:40] = item.error_addr;
                    frame_bits = 40;
                end
                APLC_SPI_AHB_WR_BURST: begin
                    data[79:72] = item.error_opcode;
                    data[74:70] = item.error_burst_len;
                    data[39:8]  = item.error_addr;
                    frame_bits = 48;
                end
                APLC_SPI_AHB_RD_BURST: begin
                    data[79:72] = item.error_opcode;
                    data[74:70] = item.error_burst_len;
                    data[39:8]  = item.error_addr;
                    frame_bits = 48;
                end
                default: begin
                    data[79:72] = item.error_opcode;
                    frame_bits = 8;
                end
            endcase
            return data;
        end

        case (item.opcode)
            APLC_SPI_WR_CSR: begin
                data[79:72] = item.opcode;
                data[71:64] = item.reg_addr;
                data[63:32] = item.wdata.size() > 0 ? item.wdata[0] : 32'h0;
                frame_bits = 48;
            end
            APLC_SPI_RD_CSR: begin
                data[79:72] = item.opcode;
                data[71:64] = item.reg_addr;
                frame_bits = 16;
            end
            APLC_SPI_AHB_WR32: begin
                data[79:72] = item.opcode;
                data[71:40] = item.addr;
                data[39:8]  = item.wdata.size() > 0 ? item.wdata[0] : 32'h0;
                frame_bits = 72;
            end
            APLC_SPI_AHB_RD32: begin
                data[79:72] = item.opcode;
                data[71:40] = item.addr;
                frame_bits = 40;
            end
            APLC_SPI_AHB_WR_BURST: begin
                data[79:72] = item.opcode;
                data[74:70] = item.burst_len;
                data[39:8]  = item.addr;
                frame_bits = 48;
            end
            APLC_SPI_AHB_RD_BURST: begin
                data[79:72] = item.opcode;
                data[74:70] = item.burst_len;
                data[39:8]  = item.addr;
                frame_bits = 48;
            end
            default: begin
                data[79:72] = item.opcode;
                frame_bits = 8;
            end
        endcase
        return data;
    endfunction

    virtual task drive_frame(bit [79:0] data, int bits, int bpc);
        int beats;
        beats = (bits + bpc - 1) / bpc;

        for (int b = 0; b < beats; b++) begin
            case (bpc)
                1: m_vif.drv_cb.pdi <= {15'b0, data[79 - b]};
                4: m_vif.drv_cb.pdi <= {12'b0, data[79 - b*4 -: 4]};
                8: m_vif.drv_cb.pdi <= {8'b0,  data[79 - b*8 -: 8]};
                16: m_vif.drv_cb.pdi <= data[79 - b*16 -: 16];
            endcase
            @(m_vif.drv_cb);
        end
    endtask

    virtual task drive_burst_write_payload(aplc_spi_item item, int bpc);
        for (int i = 0; i < item.wdata.size(); i++) begin
            bit [31:0] beat;
            int        beat_beats;
            beat = item.wdata[i];
            beat_beats = 32 / bpc;

            for (int b = 0; b < beat_beats; b++) begin
                case (bpc)
                    1: m_vif.drv_cb.pdi <= {15'b0, beat[31 - b]};
                    4: m_vif.drv_cb.pdi <= {12'b0, beat[31 - b*4 -: 4]};
                    8: m_vif.drv_cb.pdi <= {8'b0,  beat[31 - b*8 -: 8]};
                    16: m_vif.drv_cb.pdi <= beat[31 - b*16 -: 16];
                endcase
                @(m_vif.drv_cb);
            end
        end
    endtask

    virtual task collect_response(aplc_spi_item item, int bpc);
        bit [560:0] rx_data;
        int         rx_count;
        int         expected_rx_bits;

        rx_data = '0;
        rx_count = 0;

        wait (m_vif.pdo_oe === 1'b1);
        @(m_vif.drv_cb);

        while (m_vif.drv_cb.pdo_oe === 1'b1) begin
            case (bpc)
                1: begin
                    rx_data = {rx_data[559:0], m_vif.drv_cb.pdo[0]};
                    rx_count += 1;
                end
                4: begin
                    rx_data = {rx_data[555:0], m_vif.drv_cb.pdo[3:0]};
                    rx_count += 4;
                end
                8: begin
                    rx_data = {rx_data[551:0], m_vif.drv_cb.pdo[7:0]};
                    rx_count += 8;
                end
                16: begin
                    rx_data = {rx_data[543:0], m_vif.drv_cb.pdo[15:0]};
                    rx_count += 16;
                end
            endcase

            if (rx_count >= 8 && item.status == 8'h00) begin
                item.status = rx_data[559:552];
                if (item.status == APLC_SPI_STS_OK) begin
                    case (item.opcode)
                        APLC_SPI_RD_CSR:       expected_rx_bits = 40;
                        APLC_SPI_AHB_RD32:     expected_rx_bits = 40;
                        APLC_SPI_AHB_RD_BURST: expected_rx_bits = 8 + 32 * item.burst_len;
                        default:               expected_rx_bits = 8;
                    endcase
                end else begin
                    expected_rx_bits = 8;
                end
            end

            if (rx_count >= expected_rx_bits && expected_rx_bits > 0) begin
                break;
            end

            @(m_vif.drv_cb);
        end

        parse_driver_response(item, rx_data, rx_count);
    endtask

    virtual function void parse_driver_response(aplc_spi_item item,
                                                 bit [560:0] rx_data,
                                                 int rx_count);
        if (rx_count < 8) return;

        item.status = rx_data[559:552];

        if (item.status == APLC_SPI_STS_OK) begin
            case (item.opcode)
                APLC_SPI_RD_CSR: begin
                    if (rx_count >= 40) begin
                        item.rdata = new[1];
                        item.rdata[0] = rx_data[551:520];
                    end
                end
                APLC_SPI_AHB_RD32: begin
                    if (rx_count >= 40) begin
                        item.rdata = new[1];
                        item.rdata[0] = rx_data[551:520];
                    end
                end
                APLC_SPI_AHB_RD_BURST: begin
                    int n = item.burst_len;
                    if (rx_count >= 8 + 32 * n && n > 0) begin
                        item.rdata = new[n];
                        for (int i = 0; i < n; i++) begin
                            item.rdata[i] = rx_data[551 - i*32 -: 32];
                        end
                    end
                end
                default: ;
            endcase
        end
    endfunction

    protected virtual function string get_id();
        return "DRV";
    endfunction

endclass

`endif
