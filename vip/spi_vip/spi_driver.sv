/******************************************************************************
 * SPI VIP Driver
 * Description: Driver for SPI VIP - drives transactions on the SPI interface
 ******************************************************************************/

`ifndef SPI_DRIVER_SV
`define SPI_DRIVER_SV

class spi_driver extends uvm_driver#(spi_item);

    `uvm_component_utils(spi_driver)

    spi_agent_config m_config;
    spi_vif_t m_vif;

    uvm_analysis_port#(spi_item) analysis_port;

    protected process m_drive_process;

    function new(string name = "spi_driver", uvm_component parent = null);
        super.new(name, parent);
        analysis_port = new("analysis_port", this);
    endfunction

    virtual function string get_id();
        return "SPI_DRV";
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
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
        if(m_drive_process != null) begin
            m_drive_process.kill();
            `uvm_info(get_id(), "Killing drive process on reset", UVM_MEDIUM)
        end
        if(m_config.get_driving_delay() == 0) begin
            m_vif.pcs_n <= 1'b1;
            m_vif.pdi <= '0;
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
                    drive_transactions();
                    disable fork;
                end
            join
        end
    endtask

    virtual task drive_transactions();
        m_drive_process = process::self();
        `uvm_info(get_id(), "Starting drive_transactions", UVM_LOW)

        forever begin
            spi_item req;
            seq_item_port.get_next_item(req);
            analysis_port.write(req);
            drive_transaction(req);
            seq_item_port.item_done();
        end
    endtask

    virtual task drive_transaction(spi_item trans);
        logic [79:0] frame_data;
        int frame_len;
        int num_cycles;
        int bits_per_cycle;
        int cycle_idx;
        int bit_idx;

        `uvm_info(get_id(), $sformatf("Driving: %s", trans.convert2string()), UVM_LOW)

        frame_data = build_frame(trans);
        frame_len = trans.get_frame_length();
        bits_per_cycle = get_bits_per_cycle(trans.lane_mode);
        num_cycles = (frame_len + bits_per_cycle - 1) / bits_per_cycle;

        m_vif.lane_mode <= trans.lane_mode;
        m_vif.en <= 1'b1;
        m_vif.test_mode <= 1'b1;

        @(m_vif.cb);
        m_vif.cb.pcs_n <= 1'b0;

        for(cycle_idx = 0; cycle_idx < num_cycles; cycle_idx++) begin
            logic [15:0] data_word;
            data_word = '0;

            for(bit_idx = 0; bit_idx < bits_per_cycle; bit_idx++) begin
                int frame_bit_idx;
                frame_bit_idx = frame_len - (cycle_idx * bits_per_cycle) - bit_idx - 1;
                if(frame_bit_idx >= 0 && frame_bit_idx < 80) begin
                    data_word[bits_per_cycle - 1 - bit_idx] = frame_data[frame_bit_idx];
                end
            end

            m_vif.cb.pdi <= data_word;
            @(m_vif.cb);

            if(trans.inter_byte_delay > 0) begin
                repeat(trans.inter_byte_delay) @(m_vif.cb);
            end
        end

        m_vif.cb.pcs_n <= 1'b1;
        @(m_vif.cb);

        if(trans.trans_delay > 0) begin
            repeat(trans.trans_delay) @(m_vif.cb);
        end
    endtask

    virtual function logic [79:0] build_frame(spi_item trans);
        logic [79:0] frame;
        frame = '0;
        case(trans.opcode)
            CMD_WR_CSR: begin
                frame[79:72] = trans.opcode;
                frame[71:64] = trans.addr[7:0];
                frame[63:32] = trans.data;
                frame[31:0] = '0;
            end
            CMD_RD_CSR: begin
                frame[79:72] = trans.opcode;
                frame[71:64] = trans.addr[7:0];
                frame[63:0] = '0;
            end
            CMD_AHB_WR32: begin
                frame[79:72] = trans.opcode;
                frame[71:40] = trans.addr;
                frame[39:8] = trans.data;
                frame[7:0] = '0;
            end
            CMD_AHB_RD32: begin
                frame[79:72] = trans.opcode;
                frame[71:40] = trans.addr;
                frame[39:0] = '0;
            end
            CMD_AHB_WR_BURST: begin
                frame[79:72] = trans.opcode;
                frame[71:67] = trans.burst_len;
                frame[66:64] = '0;
                frame[63:32] = trans.addr;
                frame[31:0] = '0;
            end
            CMD_AHB_RD_BURST: begin
                frame[79:72] = trans.opcode;
                frame[71:67] = trans.burst_len;
                frame[66:64] = '0;
                frame[63:32] = trans.addr;
                frame[31:0] = '0;
            end
            default: frame = '0;
        endcase
        return frame;
    endfunction

endclass

`endif