// APLC SPI VIP Coverage Collector

`ifndef APLC_SPI_COVERAGE_SV
`define APLC_SPI_COVERAGE_SV

class aplc_spi_coverage extends uvm_subscriber #(aplc_spi_mon_item);

    `uvm_component_utils(aplc_spi_coverage)

    aplc_spi_agent_config m_cfg;

    covergroup cg_opcode with function sample(aplc_spi_mon_item item);
        cp_opcode: coverpoint item.opcode {
            bins wr_csr      = {APLC_OPCODE_WR_CSR};
            bins rd_csr      = {APLC_OPCODE_RD_CSR};
            bins ahb_wr32    = {APLC_OPCODE_AHB_WR32};
            bins ahb_rd32    = {APLC_OPCODE_AHB_RD32};
            bins ahb_wr_burst = {APLC_OPCODE_AHB_WR_BURST};
            bins ahb_rd_burst = {APLC_OPCODE_AHB_RD_BURST};
        }
        cp_lane_mode: coverpoint item.lane_mode {
            bins mode_1bit  = {APLC_LANE_1BIT};
            bins mode_4bit  = {APLC_LANE_4BIT};
            bins mode_8bit  = {APLC_LANE_8BIT};
            bins mode_16bit = {APLC_LANE_16BIT};
        }
        cp_status: coverpoint item.status {
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
        cp_burst_len: coverpoint item.burst_len {
            bins b1  = {5'd1};
            bins b4  = {5'd4};
            bins b8  = {5'd8};
            bins b16 = {5'd16};
        }
        cx_opcode_lane: cross cp_opcode, cp_lane_mode;
        cx_opcode_status: cross cp_opcode, cp_status;
    endgroup

    covergroup cg_fifo_status with function sample(bit rxfifo_full, bit txfifo_full);
        cp_rxfifo_full: coverpoint rxfifo_full;
        cp_txfifo_full: coverpoint txfifo_full;
    endgroup

    function new(string name, uvm_component parent);
        super.new(name, parent);
        cg_opcode = new();
        cg_fifo_status = new();
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(aplc_spi_agent_config)::get(this, "", "agent_config", m_cfg)) begin
            `uvm_warning("APLC_SPI_COV", "Cannot get agent_config")
        end
    endfunction

    virtual function void write(aplc_spi_mon_item t);
        cg_opcode.sample(t);
    endfunction

    virtual function void sample_fifo_status(bit rxfifo_full, bit txfifo_full);
        cg_fifo_status.sample(rxfifo_full, txfifo_full);
    endfunction

endclass

`endif
