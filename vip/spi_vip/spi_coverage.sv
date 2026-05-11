`ifndef SPI_COVERAGE_SV
`define SPI_COVERAGE_SV

`uvm_analysis_imp_decl(_mon)

class spi_coverage extends uvm_component;

  `uvm_component_utils(spi_coverage)

  uvm_analysis_imp_mon#(spi_mon_item, spi_coverage) mon_port;

  spi_agent_config m_agent_config;

  // Transaction covergroup
  covergroup cg_spi_transaction with function sample(spi_mon_item item);
    cp_opcode: coverpoint item.opcode {
      bins wr_csr       = {SPI_WR_CSR};
      bins rd_csr       = {SPI_RD_CSR};
      bins ahb_wr32     = {SPI_AHB_WR32};
      bins ahb_rd32     = {SPI_AHB_RD32};
      bins ahb_wr_burst = {SPI_AHB_WR_BURST};
      bins ahb_rd_burst = {SPI_AHB_RD_BURST};
    }

    cp_lane_mode: coverpoint item.lane_mode {
      bins mode_1bit  = {SPI_LANE_1BIT};
      bins mode_4bit  = {SPI_LANE_4BIT};
      bins mode_8bit  = {SPI_LANE_8BIT};
      bins mode_16bit = {SPI_LANE_16BIT};
    }

    cp_status: coverpoint item.status {
      bins ok          = {SPI_STS_OK};
      bins frame_err   = {SPI_STS_FRAME_ERR};
      bins bad_opcode  = {SPI_STS_BAD_OPCODE};
      bins not_in_test = {SPI_STS_NOT_IN_TEST};
      bins disabled    = {SPI_STS_DISABLED};
      bins bad_reg     = {SPI_STS_BAD_REG};
      bins align_err   = {SPI_STS_ALIGN_ERR};
      bins ahb_err     = {SPI_STS_AHB_ERR};
      bins bad_burst   = {SPI_STS_BAD_BURST};
      bins burst_bound = {SPI_STS_BURST_BOUND};
    }

    cp_burst_len: coverpoint item.burst_len {
      bins single = {1};
      bins incr4  = {4};
      bins incr8  = {8};
      bins incr16 = {16};
      bins illegal_zero = {0};
      bins illegal_other = {[2:3], [5:7], [9:15], [17:31]};
    }

    cp_direction: coverpoint item.direction {
      bins request  = {SPI_REQUEST};
      bins response = {SPI_RESPONSE};
    }

    cx_opcode_lane: cross cp_opcode, cp_lane_mode;
    cx_opcode_status: cross cp_opcode, cp_status;
  endgroup

  // Address covergroup
  covergroup cg_spi_addr with function sample(spi_mon_item item);
    cp_reg_addr: coverpoint item.reg_addr {
      bins low     = {[8'h00:8'h0F]};
      bins mid     = {[8'h10:8'h2F]};
      bins high    = {[8'h30:8'h3F]};
      bins illegal = {[8'h40:8'hFF]};
    }

    cp_ahb_addr_aligned: coverpoint item.addr[1:0] {
      bins aligned   = {2'b00};
      bins unaligned = {2'b01, 2'b10, 2'b11};
    }
  endgroup

  // FIFO status covergroup
  covergroup cg_spi_fifo with function sample(spi_mon_item item);
    cp_rxfifo_full: coverpoint item.rxfifo_full_obs {
      bins not_full = {0};
      bins full     = {1};
    }

    cp_txfifo_empty: coverpoint item.txfifo_empty_obs {
      bins not_empty = {0};
      bins empty     = {1};
    }

    cp_rxfifo_empty: coverpoint item.rxfifo_empty_obs {
      bins not_empty = {0};
      bins empty     = {1};
    }

    cp_txfifo_full: coverpoint item.txfifo_full_obs {
      bins not_full = {0};
      bins full     = {1};
    }
  endgroup

  function new(string name = "spi_coverage", uvm_component parent = null);
    super.new(name, parent);
    cg_spi_transaction = new();
    cg_spi_addr = new();
    cg_spi_fifo = new();
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    mon_port = new("mon_port", this);
  endfunction

  virtual function void write_mon(spi_mon_item item);
    cg_spi_transaction.sample(item);
    if (item.opcode inside {SPI_WR_CSR, SPI_RD_CSR})
      cg_spi_addr.sample(item);
    if (item.direction == SPI_RESPONSE)
      cg_spi_fifo.sample(item);
  endfunction

  virtual function void handle_reset();
    // Coverage data persists across resets
  endfunction

endclass : spi_coverage

`endif // SPI_COVERAGE_SV
