`ifndef APLC_SPI_COVERAGE_SV
`define APLC_SPI_COVERAGE_SV

class aplc_spi_coverage extends uvm_component;

    `uvm_component_utils(aplc_spi_coverage)

    uvm_analysis_imp #(aplc_spi_mon_item, aplc_spi_coverage) item_from_mon;

    covergroup cg_opcode;
        cp_opcode: coverpoint m_item.opcode {
            bins wr_csr       = {APLC_SPI_WR_CSR};
            bins rd_csr       = {APLC_SPI_RD_CSR};
            bins ahb_wr32     = {APLC_SPI_AHB_WR32};
            bins ahb_rd32     = {APLC_SPI_AHB_RD32};
            bins ahb_wr_burst = {APLC_SPI_AHB_WR_BURST};
            bins ahb_rd_burst = {APLC_SPI_AHB_RD_BURST};
        }
    endgroup

    covergroup cg_lane_mode;
        cp_lane_mode: coverpoint m_item.lane_mode {
            bins mode_1bit  = {2'b00};
            bins mode_4bit  = {2'b01};
            bins mode_8bit  = {2'b10};
            bins mode_16bit = {2'b11};
        }
    endgroup

    covergroup cg_status;
        cp_status: coverpoint m_item.status {
            bins ok          = {8'h00};
            bins frame_err   = {8'h01};
            bins bad_opcode  = {8'h02};
            bins not_in_test = {8'h04};
            bins disabled    = {8'h08};
            bins bad_reg     = {8'h10};
            bins align_err   = {8'h20};
            bins ahb_err     = {8'h40};
            bins bad_burst   = {8'h80};
            bins burst_bound = {8'h81};
        }
    endgroup

    covergroup cg_burst_len;
        cp_burst_len: coverpoint m_item.burst_len {
            bins len_1  = {1};
            bins len_4  = {4};
            bins len_8  = {8};
            bins len_16 = {16};
        }
    endgroup

    covergroup cg_opcode_lane_cross;
        cp_opcode: coverpoint m_item.opcode {
            bins wr_csr       = {APLC_SPI_WR_CSR};
            bins rd_csr       = {APLC_SPI_RD_CSR};
            bins ahb_wr32     = {APLC_SPI_AHB_WR32};
            bins ahb_rd32     = {APLC_SPI_AHB_RD32};
            bins ahb_wr_burst = {APLC_SPI_AHB_WR_BURST};
            bins ahb_rd_burst = {APLC_SPI_AHB_RD_BURST};
        }
        cp_lane_mode: coverpoint m_item.lane_mode {
            bins mode_1bit  = {2'b00};
            bins mode_4bit  = {2'b01};
            bins mode_8bit  = {2'b10};
            bins mode_16bit = {2'b11};
        }
        cross cp_opcode, cp_lane_mode;
    endgroup

    covergroup cg_fifo_status;
        cp_rxfifo_empty: coverpoint m_rxfifo_empty;
        cp_rxfifo_full:  coverpoint m_rxfifo_full;
        cp_txfifo_empty: coverpoint m_txfifo_empty;
        cp_txfifo_full:  coverpoint m_txfifo_full;
    endgroup

    protected aplc_spi_mon_item m_item;
    protected bit m_rxfifo_empty;
    protected bit m_rxfifo_full;
    protected bit m_txfifo_empty;
    protected bit m_txfifo_full;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        cg_opcode            = new();
        cg_lane_mode         = new();
        cg_status            = new();
        cg_burst_len         = new();
        cg_opcode_lane_cross = new();
        cg_fifo_status       = new();
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        item_from_mon = new("item_from_mon", this);
    endfunction

    virtual function void write(aplc_spi_mon_item item);
        m_item = item;
        cg_opcode.sample();
        cg_lane_mode.sample();
        cg_status.sample();
        if (item.opcode inside {APLC_SPI_AHB_WR_BURST, APLC_SPI_AHB_RD_BURST}) begin
            cg_burst_len.sample();
        end
        cg_opcode_lane_cross.sample();
    endfunction

    virtual function void sample_fifo_status(bit rxfifo_empty, bit rxfifo_full,
                                             bit txfifo_empty, bit txfifo_full);
        m_rxfifo_empty = rxfifo_empty;
        m_rxfifo_full  = rxfifo_full;
        m_txfifo_empty = txfifo_empty;
        m_txfifo_full  = txfifo_full;
        cg_fifo_status.sample();
    endfunction

endclass

`endif
