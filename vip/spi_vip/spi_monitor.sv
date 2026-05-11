/******************************************************************************
 * SPI VIP Monitor
 * Description: Monitor for SPI VIP - monitors transactions on the SPI interface
 ******************************************************************************/

`ifndef SPI_MONITOR_SV
`define SPI_MONITOR_SV

class spi_monitor extends uvm_monitor;

    `uvm_component_utils(spi_monitor)

    spi_agent_config m_config;
    spi_vif_t m_vif;

    uvm_analysis_port#(spi_item) analysis_port;

    protected process m_collect_process;

    function new(string name = "spi_monitor", uvm_component parent = null);
        super.new(name, parent);
        analysis_port = new("analysis_port", this);
    endfunction

    virtual function string get_id();
        return "SPI_MON";
    endfunction

    virtual function void start_of_simulation_phase(input uvm_phase phase);
        super.start_of_simulation_phase(phase);
        assert(m_config != null) else
            `uvm_fatal(get_id(), "Agent config is null");
        m_vif = m_config.get_dut_vif();
        assert(m_vif != null) else
            `uvm_fatal(get_id(), "Virtual interface is null");
    endfunction

    virtual function void handle_reset();
        if(m_collect_process != null) begin
            m_collect_process.kill();
            `uvm_info(get_id(), "Killing collect process on reset", UVM_MEDIUM)
        end
    endfunction

    virtual task wait_reset_end();
        m_config.wait_reset_end();
    endtask

    virtual task run_phase(uvm_phase phase);
        forever begin
            fork
                begin
                    wait_reset_end();
                    collect_transactions();
                    disable fork;
                end
            join
        end
    endtask

    virtual task collect_transactions();
        m_collect_process = process::self();
        `uvm_info(get_id(), "Starting collect_transactions", UVM_LOW)

        forever begin
            spi_item trans;
            trans = spi_item::type_id::create("trans");
            collect_transaction(trans);
            analysis_port.write(trans);
        end
    endtask

    virtual task collect_transaction(spi_item trans);
        spi_lane_mode_t lane_mode_val;
        int bpc_val;
        logic [79:0] rx_data;
        int rx_count;
        int expected_bits;

        while(m_vif.cb_mon.pcs_n === 1'b1) begin
            @(m_vif.cb_mon);
        end

        trans.start_time = $time;
        lane_mode_val = spi_lane_mode_t'(m_vif.cb_mon.lane_mode);
        trans.lane_mode = lane_mode_val;
        bpc_val = get_bits_per_cycle(lane_mode_val);

        rx_count = 0;
        rx_data = '0;
        expected_bits = 8;

        while(m_vif.cb_mon.pcs_n === 1'b0) begin
            logic [15:0] pdi_word;
            pdi_word = m_vif.cb_mon.pdi;

            case(bpc_val)
                1:  rx_data = {rx_data[78:0], pdi_word[0]};
                4:  rx_data = {rx_data[75:0], pdi_word[3:0]};
                8:  rx_data = {rx_data[71:0], pdi_word[7:0]};
                16: rx_data = {rx_data[63:0], pdi_word[15:0]};
                default: rx_data = {rx_data[63:0], pdi_word[15:0]};
            endcase
            rx_count += bpc_val;

            if(rx_count == 8) begin
                trans.opcode = spi_opcode_t'(rx_data[7:0]);
                expected_bits = get_expected_frame_length(trans.opcode);
            end

            if(rx_count == 16 && trans.opcode inside {CMD_AHB_WR_BURST, CMD_AHB_RD_BURST}) begin
                trans.burst_len = rx_data[12:8];
                if(trans.opcode == CMD_AHB_WR_BURST) begin
                    expected_bits = 48 + 32 * trans.burst_len;
                end
            end

            if(rx_count >= expected_bits && m_vif.cb_mon.pcs_n === 1'b0) begin
                @(m_vif.cb_mon);
                if(m_vif.cb_mon.pcs_n === 1'b1) break;
            end else begin
                @(m_vif.cb_mon);
            end
        end

        parse_rx_data(trans, rx_data, rx_count);

        wait_for_response(trans);

        trans.end_time = $time;
        `uvm_info(get_id(), $sformatf("Collected: %s", trans.convert2string()), UVM_LOW)
    endtask

    virtual task wait_for_response(spi_item trans);
        spi_lane_mode_t lane_mode_val;
        int bpc_val;
        int resp_len;
        int resp_cycles;
        logic [511:0] resp_data;
        int resp_count;

        lane_mode_val = trans.lane_mode;
        bpc_val = get_bits_per_cycle(lane_mode_val);
        resp_len = trans.get_response_length();
        resp_cycles = (resp_len + bpc_val - 1) / bpc_val;

        while(m_vif.cb_mon.pdo_oe === 1'b0 && m_vif.cb_mon.pcs_n === 1'b0) begin
            @(m_vif.cb_mon);
        end

        if(m_vif.cb_mon.pdo_oe === 1'b1) begin
            resp_count = 0;
            resp_data = '0;

            repeat(resp_cycles) begin
                logic [15:0] pdo_word;
                pdo_word = m_vif.cb_mon.pdo;

                case(bpc_val)
                    1:  resp_data = {resp_data[510:0], pdo_word[0]};
                    4:  resp_data = {resp_data[507:0], pdo_word[3:0]};
                    8:  resp_data = {resp_data[503:0], pdo_word[7:0]};
                    16: resp_data = {resp_data[495:0], pdo_word[15:0]};
                    default: resp_data = {resp_data[495:0], pdo_word[15:0]};
                endcase
                resp_count += bpc_val;

                @(m_vif.cb_mon);
            end

            trans.status = spi_status_t'(resp_data[7:0]);
            trans.has_response = 1;

            if(trans.opcode == CMD_RD_CSR || trans.opcode == CMD_AHB_RD32) begin
                trans.data = resp_data[39:8];
            end else if(trans.opcode == CMD_AHB_RD_BURST) begin
                for(int i = 0; i < trans.burst_len && i < 16; i++) begin
                    trans.rdata_queue.push_back(resp_data[(i+1)*32 + 7 -: 32]);
                end
            end
        end
    endtask

    virtual function void parse_rx_data(spi_item trans, logic [79:0] rx_data, int rx_count);
        case(trans.opcode)
            CMD_WR_CSR: begin
                trans.addr = {16'h0, rx_data[71:64]};
                trans.data = rx_data[63:32];
                trans.direction = DIR_WRITE;
            end
            CMD_RD_CSR: begin
                trans.addr = {16'h0, rx_data[71:64]};
                trans.direction = DIR_READ;
            end
            CMD_AHB_WR32: begin
                trans.addr = rx_data[71:40];
                trans.data = rx_data[39:8];
                trans.direction = DIR_WRITE;
            end
            CMD_AHB_RD32: begin
                trans.addr = rx_data[71:40];
                trans.direction = DIR_READ;
            end
            CMD_AHB_WR_BURST: begin
                trans.addr = rx_data[63:32];
                trans.direction = DIR_WRITE;
            end
            CMD_AHB_RD_BURST: begin
                trans.addr = rx_data[63:32];
                trans.direction = DIR_READ;
            end
        endcase
    endfunction

    virtual function int get_expected_frame_length(spi_opcode_t opcode);
        case(opcode)
            CMD_WR_CSR: return 48;
            CMD_RD_CSR: return 16;
            CMD_AHB_WR32: return 72;
            CMD_AHB_RD32: return 40;
            CMD_AHB_WR_BURST: return 48;
            CMD_AHB_RD_BURST: return 48;
            default: return 8;
        endcase
    endfunction

endclass

`endif
