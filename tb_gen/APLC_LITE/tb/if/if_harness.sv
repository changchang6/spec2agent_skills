`ifndef IF_HARNESS_SV
`define IF_HARNESS_SV

interface if_harness();
	spi_if m_spi_vif ( // AI gen: added fifo status signals
     .clk (APLC_LITE.clk)
     .rst_n (APLC_LITE.rst_n)
     .en (APLC_LITE.en)
     .test_mode (APLC_LITE.test_mode)
     .pcs_n (APLC_LITE.pcs_n)
     .pdi (APLC_LITE.pdi)
     .pdo (APLC_LITE.pdo)
     .pdo_oe (APLC_LITE.pdo_oe)
     .lane_mode (APLC_LITE.lane_mode)
     .rxfifo_empty (APLC_LITE.rxfifo_empty)
     .rxfifo_full (APLC_LITE.rxfifo_full)
     .txfifo_empty (APLC_LITE.txfifo_empty)
     .txfifo_full (APLC_LITE.txfifo_full)
     );

   fifo_if m_fifo_vif ( 
     .clk (APLC_LITE.clk)
     .rst_n (APLC_LITE.rst_n)
     .rxfifo_empty (APLC_LITE.rxfifo_empty)
     .rxfifo_full (APLC_LITE.rxfifo_full)
     .txfifo_empty (APLC_LITE.txfifo_empty)
     .txfifo_full (APLC_LITE.txfifo_full) 
     );

   csr_if m_csr_vif ( 
     .clk (APLC_LITE.clk)
     .rst_n (APLC_LITE.rst_n)
     .csr_rd_en (APLC_LITE.csr_rd_en)
     .csr_wr_en (APLC_LITE.csr_wr_en)
     .csr_addr (APLC_LITE.csr_addr)
     .csr_wdata (APLC_LITE.csr_wdata)
     .csr_rdata (APLC_LITE.csr_rdata) 
     );

	
	function void set_spi_vif(string path);
   uvm_config_db#(virtual spi_if)::set(null, path, "spi_vif", m_spi_vif);
  endfunction

  function void set_fifo_vif(string path);
   uvm_config_db#(virtual fifo_if)::set(null, path, "fifo_vif", m_fifo_vif);
  endfunction

  function void set_csr_vif(string path);
   uvm_config_db#(virtual csr_if)::set(null, path, "csr_vif", m_csr_vif);
  endfunction


endinterface
`endif 