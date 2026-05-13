// APLC SPI Coverage Collector
`ifndef APLC_SPI_COVERAGE_SV
`define APLC_SPI_COVERAGE_SV

class aplc_spi_coverage extends uvm_subscriber #(aplc_spi_mon_item);

    `uvm_component_utils(aplc_spi_coverage)

    uvm_analysis_imp #(aplc_spi_mon_item, aplc_spi_coverage) m_mon_imp;

    // Covergroup for command coverage
    covergroup cg_cmd;
        cp_opcode: coverpoint m_item.opcode {
            bins wr_csr     = {APLC_OP_WR_CSR};
            bins rd_csr     = {APLC_OP_RD_CSR};
            bins ahb_wr32   = {APLC_OP_AHB_WR32};
            bins ahb_rd32   = {APLC_OP_AHB_RD32};
            bins ahb_wr_burst = {APLC_OP_AHB_WR_BURST};
            bins ahb_rd_burst = {APLC_OP_AHB_RD_BURST};
            bins bad_opcode = default;
        }
        cp_lane_mode: coverpoint m_item.lane_mode {
            bins lane_1bit  = {APLC_LANE_1BIT};
            bins lane_4bit  = {APLC_LANE_4BIT};
            bins lane_8bit  = {APLC_LANE_8BIT};
            bins lane_16bit = {APLC_LANE_16BIT};
        }
        cp_status: coverpoint m_item.status {
            bins ok          = {APLC_STS_OK};
            bins frame_err   = {APLC_STS_FRAME_ERR};
            bins bad_opcode  = {APLC_STS_BAD_OPCODE};
            bins not_in_test = {APLC_STS_NOT_IN_TEST};
            bins disabled    = {APLC_STS_DISABLED};
            bins bad_reg     = {APLC_STS_BAD_REG};
            bins align_err   = {APLC_STS_ALIGN_ERR};
            bins ahb_err     = {APLC_STS_AHB_ERR};
            bins bad_burst   = {APLC_STS_BAD_BURST};
            bins burst_bound = {APLC_STS_BURST_BOUND};
        }
        cp_burst_len: coverpoint m_item.burst_len {
            bins len_1  = {5'd1};
            bins len_4  = {5'd4};
            bins len_8  = {5'd8};
            bins len_16 = {5'd16};
            bins illegal = default;
        }
        cp_frame_abort: coverpoint m_item.frame_abort {
            bins no_abort = {0};
            bins aborted  = {1};
        }
        cross_opcode_lane: cross cp_opcode, cp_lane_mode;
    endgroup

    protected aplc_spi_mon_item m_item;

    function new(string name = "aplc_spi_coverage", uvm_component parent = null);
        super.new(name, parent);
        m_mon_imp = new("m_mon_imp", this);
        cg_cmd = new();
    endfunction

    virtual function void write(aplc_spi_mon_item t);
        m_item = t;
        cg_cmd.sample();
    endfunction

endclass

`endif
