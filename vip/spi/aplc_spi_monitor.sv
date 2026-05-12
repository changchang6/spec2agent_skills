`ifndef APLC_SPI_MONITOR_SV
`define APLC_SPI_MONITOR_SV

class aplc_spi_monitor extends uvm_monitor;

    `uvm_component_utils(aplc_spi_monitor)

    uvm_analysis_port #(aplc_spi_mon_item) output_port;

    protected aplc_spi_vif_t         m_vif;
    protected aplc_spi_agent_config  m_config;
    protected process                m_collect_process;

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
        fork
            collect_transactions();
            reset_handler();
        join
    endtask

    virtual task collect_transactions();
        forever begin
            aplc_spi_mon_item item;
            wait (m_vif.rst_n === 1'b1);
            @(m_vif.mon_cb);
            wait (m_vif.mon_cb.pcs_n === 1'b0);
            item = aplc_spi_mon_item::type_id::create("item");
            item.start_time = $time;
            item.has_frame_abort  = 1'b0;
            item.has_lane_changed = 1'b0;
            item.has_ta_err       = 1'b0;

            collect_request(item);
            collect_response(item);

            item.end_time = $time;
            print_transaction(item);
            output_port.write(item);
        end
    endtask

    virtual task collect_request(aplc_spi_mon_item item);
        bit [79:0] rx_shift;
        int        rx_count;
        int        expected_bits;
        bit [7:0]  opcode_latched;
        bit [4:0]  bl;
        bit        frame_done;

        rx_shift    = '0;
        rx_count    = 0;
        expected_bits = 8;
        frame_done  = 1'b0;
        item.lane_mode = m_vif.mon_cb.lane_mode;

        while (!frame_done && m_vif.mon_cb.pcs_n === 1'b0) begin
            @(m_vif.mon_cb);
            if (m_vif.mon_cb.pcs_n === 1'b1) begin
                item.has_frame_abort = 1'b1;
                break;
            end
            if (m_vif.mon_cb.pdo_oe === 1'b1) begin
                break;
            end

            case (item.lane_mode)
                2'b00: begin
                    rx_shift = {rx_shift[78:0], m_vif.mon_cb.pdi[0]};
                    rx_count += 1;
                end
                2'b01: begin
                    rx_shift = {rx_shift[75:0], m_vif.mon_cb.pdi[3:0]};
                    rx_count += 4;
                end
                2'b10: begin
                    rx_shift = {rx_shift[71:0], m_vif.mon_cb.pdi[7:0]};
                    rx_count += 8;
                end
                2'b11: begin
                    rx_shift = {rx_shift[63:0], m_vif.mon_cb.pdi[15:0]};
                    rx_count += 16;
                end
            endcase

            if (rx_count >= 8 && opcode_latched == 8'h00) begin
                opcode_latched = rx_shift[79:72];
                item.opcode = aplc_spi_opcode_t'(opcode_latched);
                case (opcode_latched)
                    8'h10: expected_bits = 48;
                    8'h11: expected_bits = 16;
                    8'h20: expected_bits = 72;
                    8'h21: expected_bits = 40;
                    8'h22: expected_bits = 48;
                    8'h23: expected_bits = 48;
                    default: expected_bits = rx_count;
                endcase
            end

            if (rx_count >= 16 && opcode_latched == 8'h22) begin
                bl = rx_shift[74:70];
                item.burst_len = bl;
                expected_bits = 48 + 32 * bl;
            end

            if (opcode_latched != 8'h00 && rx_count >= expected_bits) begin
                frame_done = 1'b1;
            end
        end

        if (!item.has_frame_abort) begin
            parse_request_fields(item, rx_shift, opcode_latched, rx_count);
        end
    endtask

    virtual function void parse_request_fields(aplc_spi_mon_item item,
                                                bit [79:0] rx_shift,
                                                bit [7:0]  opcode_latched,
                                                int        rx_count);
        case (opcode_latched)
            8'h10: begin
                item.opcode   = APLC_SPI_WR_CSR;
                item.reg_addr = rx_shift[71:64];
                item.wdata    = new[1];
                item.wdata[0] = rx_shift[63:32];
            end
            8'h11: begin
                item.opcode   = APLC_SPI_RD_CSR;
                item.reg_addr = rx_shift[71:64];
            end
            8'h20: begin
                item.opcode = APLC_SPI_AHB_WR32;
                item.addr   = rx_shift[71:40];
                item.wdata  = new[1];
                item.wdata[0] = rx_shift[39:8];
            end
            8'h21: begin
                item.opcode = APLC_SPI_AHB_RD32;
                item.addr   = rx_shift[71:40];
            end
            8'h22: begin
                item.opcode    = APLC_SPI_AHB_WR_BURST;
                item.burst_len = rx_shift[74:70];
                item.addr      = rx_shift[39:8];
                item.wdata     = new[item.burst_len];
            end
            8'h23: begin
                item.opcode    = APLC_SPI_AHB_RD_BURST;
                item.burst_len = rx_shift[74:70];
                item.addr      = rx_shift[39:8];
            end
            default: begin
                item.opcode = aplc_spi_opcode_t'(opcode_latched);
            end
        endcase
    endfunction

    virtual task collect_response(aplc_spi_mon_item item);
        bit [560:0] tx_shift;
        int         tx_count;
        int         expected_tx_bits;

        if (item.has_frame_abort) return;

        wait (m_vif.mon_cb.pdo_oe === 1'b1);
        @(m_vif.mon_cb);

        tx_shift = '0;
        tx_count = 0;
        expected_tx_bits = 8;

        while (m_vif.mon_cb.pdo_oe === 1'b1) begin
            case (item.lane_mode)
                2'b00: begin
                    tx_shift = {tx_shift[559:0], m_vif.mon_cb.pdo[0]};
                    tx_count += 1;
                end
                2'b01: begin
                    tx_shift = {tx_shift[555:0], m_vif.mon_cb.pdo[3:0]};
                    tx_count += 4;
                end
                2'b10: begin
                    tx_shift = {tx_shift[551:0], m_vif.mon_cb.pdo[7:0]};
                    tx_count += 8;
                end
                2'b11: begin
                    tx_shift = {tx_shift[543:0], m_vif.mon_cb.pdo[15:0]};
                    tx_count += 16;
                end
            endcase

            if (tx_count >= 8 && item.status == 8'h00) begin
                item.status = tx_shift[559:552];
                case (item.opcode)
                    APLC_SPI_RD_CSR:       expected_tx_bits = 40;
                    APLC_SPI_AHB_RD32:     expected_tx_bits = 40;
                    APLC_SPI_AHB_RD_BURST: expected_tx_bits = 8 + 32 * item.burst_len;
                    default:               expected_tx_bits = 8;
                endcase
                if (item.status != APLC_SPI_STS_OK) begin
                    expected_tx_bits = 8;
                end
            end

            if (tx_count >= expected_tx_bits && expected_tx_bits > 0) begin
                break;
            end

            @(m_vif.mon_cb);
        end

        parse_response_fields(item, tx_shift, tx_count);
    endtask

    virtual function void parse_response_fields(aplc_spi_mon_item item,
                                                 bit [560:0] tx_shift,
                                                 int         tx_count);
        if (tx_count < 8) return;

        item.status = tx_shift[559:552];

        if (item.status == APLC_SPI_STS_OK) begin
            case (item.opcode)
                APLC_SPI_RD_CSR: begin
                    if (tx_count >= 40) begin
                        item.rdata = new[1];
                        item.rdata[0] = tx_shift[551:520];
                    end
                end
                APLC_SPI_AHB_RD32: begin
                    if (tx_count >= 40) begin
                        item.rdata = new[1];
                        item.rdata[0] = tx_shift[551:520];
                    end
                end
                APLC_SPI_AHB_RD_BURST: begin
                    int n = item.burst_len;
                    if (tx_count >= 8 + 32 * n && n > 0) begin
                        item.rdata = new[n];
                        for (int i = 0; i < n; i++) begin
                            item.rdata[i] = tx_shift[551 - i*32 -: 32];
                        end
                    end
                end
                default: ;
            endcase
        end
    endfunction

    virtual function void print_transaction(aplc_spi_mon_item item);
        `uvm_info(get_id(), $sformatf("Collected item: %s", item.convert2string()), UVM_LOW)
    endfunction

    virtual task reset_handler();
        forever begin
            wait (m_vif.rst_n === 1'b0);
            if (m_collect_process != null) begin
                m_collect_process.kill();
                m_collect_process = null;
            end
            wait (m_vif.rst_n === 1'b1);
        end
    endtask

    protected virtual function string get_id();
        return "MON";
    endfunction

endclass

`endif
