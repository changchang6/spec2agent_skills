`ifndef APLC_SPI_COVERAGE_SV
`define APLC_SPI_COVERAGE_SV

class aplc_spi_coverage extends uvm_subscriber #(aplc_spi_mon_item);
    `uvm_component_utils(aplc_spi_coverage)

    aplc_spi_mon_item m_item;

    covergroup cg_spi;
        cp_opcode: coverpoint m_item.opcode {
            bins wr_csr      = {APLC_OP_WR_CSR};
            bins rd_csr      = {APLC_OP_RD_CSR};
            bins ahb_wr32    = {APLC_OP_AHB_WR32};
            bins ahb_rd32    = {APLC_OP_AHB_RD32};
            bins wr_burst    = {APLC_OP_AHB_WR_BURST};
            bins rd_burst    = {APLC_OP_AHB_RD_BURST};
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
        cp_direction: coverpoint m_item.is_response {
            bins request  = {0};
            bins response = {1};
        }
        cp_burst_len: coverpoint m_item.burst_len {
            bins bl4  = {5'd4};
            bins bl8  = {5'd8};
            bins bl16 = {5'd16};
            bins illegal = default;
        }
        cross_opcode_lane: cross cp_opcode, cp_lane_mode;
        cross_opcode_status: cross cp_opcode, cp_status;
    endgroup

    function new(string name, uvm_component parent);
        super.new(name, parent);
        cg_spi = new();
    endfunction

    virtual function void write(aplc_spi_mon_item t);
        m_item = t;
        cg_spi.sample();
    endfunction
endclass

`endif
