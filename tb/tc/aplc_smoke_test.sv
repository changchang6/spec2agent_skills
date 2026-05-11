`ifndef APLC_SMOKE_TEST_SV
`define APLC_SMOKE_TEST_SV

class aplc_smoke_test extends aplc_base_test;

  `uvm_component_utils(aplc_smoke_test)

  function new(string name = "aplc_smoke_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    spi_wr_csr_seq      wr_csr_seq;
    spi_rd_csr_seq      rd_csr_seq;
    spi_ahb_wr32_seq    ahb_wr_seq;
    spi_ahb_rd32_seq    ahb_rd_seq;
    spi_ahb_rd_burst_seq ahb_rd_burst_seq;
    spi_random_seq      rand_seq;

    super.run_phase(phase);
    phase.raise_objection(this);

    // Wait for reset to deassert
    m_spi_agent_cfg.wait_reset_end();
    #100;

    // --- Test 1: WR_CSR to CTRL register (addr=0x04, enable DUT) ---
    `uvm_info(get_type_name(), "=== Test 1: WR_CSR CTRL ===", UVM_LOW)
    wr_csr_seq = spi_wr_csr_seq::type_id::create("wr_csr_seq");
    wr_csr_seq.reg_addr = 8'h04;  // CTRL
    wr_csr_seq.wdata    = 32'h0000_0001; // EN=1
    wr_csr_seq.lane_mode = SPI_LANE_16BIT;
    wr_csr_seq.start(m_env.m_spi_agent.m_sequencer);

    // --- Test 2: RD_CSR from VERSION register ---
    `uvm_info(get_type_name(), "=== Test 2: RD_CSR VERSION ===", UVM_LOW)
    rd_csr_seq = spi_rd_csr_seq::type_id::create("rd_csr_seq");
    rd_csr_seq.reg_addr  = 8'h00;  // VERSION
    rd_csr_seq.lane_mode = SPI_LANE_16BIT;
    rd_csr_seq.start(m_env.m_spi_agent.m_sequencer);

    // --- Test 3: AHB_WR32 ---
    `uvm_info(get_type_name(), "=== Test 3: AHB_WR32 ===", UVM_LOW)
    ahb_wr_seq = spi_ahb_wr32_seq::type_id::create("ahb_wr_seq");
    ahb_wr_seq.addr      = 32'h0000_1000;
    ahb_wr_seq.wdata     = 32'hDEAD_BEEF;
    ahb_wr_seq.lane_mode = SPI_LANE_16BIT;
    ahb_wr_seq.start(m_env.m_spi_agent.m_sequencer);

    // --- Test 4: AHB_RD32 ---
    `uvm_info(get_type_name(), "=== Test 4: AHB_RD32 ===", UVM_LOW)
    ahb_rd_seq = spi_ahb_rd32_seq::type_id::create("ahb_rd_seq");
    ahb_rd_seq.addr      = 32'h0000_1000;
    ahb_rd_seq.lane_mode = SPI_LANE_16BIT;
    ahb_rd_seq.start(m_env.m_spi_agent.m_sequencer);

    // --- Test 5: AHB_RD_BURST x4 ---
    `uvm_info(get_type_name(), "=== Test 5: AHB_RD_BURST x4 ===", UVM_LOW)
    ahb_rd_burst_seq = spi_ahb_rd_burst_seq::type_id::create("ahb_rd_burst_seq");
    ahb_rd_burst_seq.addr      = 32'h0000_1000;
    ahb_rd_burst_seq.burst_len = 5'd4;
    ahb_rd_burst_seq.lane_mode = SPI_LANE_16BIT;
    ahb_rd_burst_seq.start(m_env.m_spi_agent.m_sequencer);

    // --- Test 6: 8-bit lane mode ---
    `uvm_info(get_type_name(), "=== Test 6: 8-bit lane WR_CSR ===", UVM_LOW)
    wr_csr_seq = spi_wr_csr_seq::type_id::create("wr_csr_seq_8bit");
    wr_csr_seq.reg_addr  = 8'h08;  // STATUS
    wr_csr_seq.wdata     = 32'h0000_0000;
    wr_csr_seq.lane_mode = SPI_LANE_8BIT;
    wr_csr_seq.start(m_env.m_spi_agent.m_sequencer);

    // --- Test 7: 4-bit lane mode ---
    `uvm_info(get_type_name(), "=== Test 7: 4-bit lane RD_CSR ===", UVM_LOW)
    rd_csr_seq = spi_rd_csr_seq::type_id::create("rd_csr_seq_4bit");
    rd_csr_seq.reg_addr  = 8'h00;
    rd_csr_seq.lane_mode = SPI_LANE_4BIT;
    rd_csr_seq.start(m_env.m_spi_agent.m_sequencer);

    // --- Test 8: Random transactions ---
    `uvm_info(get_type_name(), "=== Test 8: Random transactions ===", UVM_LOW)
    rand_seq = spi_random_seq::type_id::create("rand_seq");
    rand_seq.num_transactions = 5;
    rand_seq.start(m_env.m_spi_agent.m_sequencer);

    `uvm_info(get_type_name(), "=== All smoke tests completed ===", UVM_LOW)
    phase.drop_objection(this);
  endtask

endclass : aplc_smoke_test

`endif // APLC_SMOKE_TEST_SV
