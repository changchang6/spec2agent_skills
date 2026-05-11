/******************************************************************************
 * SPI VIP Coverage
 * Description: Coverage collector for SPI VIP
 ******************************************************************************/

`ifndef SPI_COVERAGE_SV
`define SPI_COVERAGE_SV

`uvm_analysis_imp_decl(_from_mon)

class spi_coverage extends uvm_component;

    `uvm_component_utils(spi_coverage)

    spi_agent_config m_config;

    uvm_analysis_imp_from_mon#(spi_item, spi_coverage) analysis_port;

    protected spi_item m_collected_items[$];

    covergroup cg_spi_transaction with function sample(spi_item trans);
        option.per_instance = 1;

        cp_opcode: coverpoint trans.opcode {
            type_option.comment = "SPI opcode type";
            bins wr_csr = {CMD_WR_CSR};
            bins rd_csr = {CMD_RD_CSR};
            bins ahb_wr32 = {CMD_AHB_WR32};
            bins ahb_rd32 = {CMD_AHB_RD32};
            bins ahb_wr_burst = {CMD_AHB_WR_BURST};
            bins ahb_rd_burst = {CMD_AHB_RD_BURST};
        }

        cp_lane_mode: coverpoint trans.lane_mode {
            type_option.comment = "Lane mode";
            bins mode_1bit = {LANE_MODE_1BIT};
            bins mode_4bit = {LANE_MODE_4BIT};
            bins mode_8bit = {LANE_MODE_8BIT};
            bins mode_16bit = {LANE_MODE_16BIT};
        }

        cp_direction: coverpoint trans.direction {
            type_option.comment = "Transaction direction";
        }

        cp_status: coverpoint trans.status {
            type_option.comment = "Response status";
            bins ok = {STS_OK};
            bins frame_err = {STS_FRAME_ERR};
            bins bad_opcode = {STS_BAD_OPCODE};
            bins not_in_test = {STS_NOT_IN_TEST};
            bins disabled = {STS_DISABLED};
            bins bad_reg = {STS_BAD_REG};
            bins align_err = {STS_ALIGN_ERR};
            bins ahb_err = {STS_AHB_ERR};
            bins bad_burst = {STS_BAD_BURST};
            bins burst_bound = {STS_BURST_BOUND};
        }

        cp_burst_len: coverpoint trans.burst_len {
            type_option.comment = "Burst length";
            bins len_1 = {1};
            bins len_4 = {4};
            bins len_8 = {8};
            bins len_16 = {16};
        }

        cp_addr_aligned: coverpoint trans.addr[1:0] {
            type_option.comment = "Address alignment";
            bins aligned = {2'b00};
            bins misaligned = default;
        }

        cx_opcode_lane: cross cp_opcode, cp_lane_mode;

        cx_opcode_status: cross cp_opcode, cp_status;

        cx_opcode_direction: cross cp_opcode, cp_direction;

        cp_addr_bits: coverpoint trans.addr {
            type_option.comment = "Address distribution";
            bins addr_low = {[32'h0000_0000:32'h0000_00FF]};
            bins addr_mid = {[32'h0000_0100:32'h0000_FFFF]};
            bins addr_high = {[32'h0001_0000:32'hFFFF_FFFF]};
        }

        cp_data_bits: coverpoint trans.data {
            type_option.comment = "Data distribution";
            bins data_zero = {32'h0000_0000};
            bins data_low = {[32'h0000_0001:32'h0000_00FF]};
            bins data_mid = {[32'h0000_0100:32'h00FF_FF00]};
            bins data_high = {[32'h00FF_FF01:32'hFFFF_FFFE]};
            bins data_ones = {32'hFFFF_FFFF};
        }
    endgroup

    covergroup cg_spi_transitions with function sample(spi_item trans);
        option.per_instance = 1;

        cp_trans_opcode: coverpoint trans.opcode {
            bins transitions[] = (CMD_WR_CSR, CMD_RD_CSR, CMD_AHB_WR32, CMD_AHB_RD32,
                                   CMD_AHB_WR_BURST, CMD_AHB_RD_BURST =>
                                   CMD_WR_CSR, CMD_RD_CSR, CMD_AHB_WR32, CMD_AHB_RD32,
                                   CMD_AHB_WR_BURST, CMD_AHB_RD_BURST);
        }
    endgroup

    function new(string name = "spi_coverage", uvm_component parent = null);
        super.new(name, parent);
        analysis_port = new("analysis_port", this);

        cg_spi_transaction = new();
        cg_spi_transaction.set_inst_name($sformatf("%s_transaction", get_full_name()));

        cg_spi_transitions = new();
        cg_spi_transitions.set_inst_name($sformatf("%s_transitions", get_full_name()));
    endfunction

    virtual function void write_from_mon(spi_item trans);
        cg_spi_transaction.sample(trans);

        if(m_collected_items.size() > 0) begin
            cg_spi_transitions.sample(trans);
        end

        m_collected_items.push_back(trans);

        if(m_collected_items.size() > 10) begin
            void'(m_collected_items.pop_front());
        end
    endfunction

    virtual function void handle_reset();
        m_collected_items.delete();
    endfunction

endclass

`endif
