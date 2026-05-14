`ifndef IF_HARNESS_SV
`define IF_HARNESS_SV

interface if_harness();
    import uvm_pkg::*;
    spi_if m_spi_vif (
        .clk       (test1.clk),
        .rst_n     (test1.rst_n),
        .en        (test1.en),
        .test_mode (test1.test_mode),
        .pcs_n     (test1.pcs_n),
        .pdi       (test1.pdi),
        .pdo       (test1.pdo),
        .pdo_oe    (test1.pdo_oe),
        .lane_mode (test1.lane_mode),
        .rxfifo_empty (test1.rxfifo_empty),
        .rxfifo_full  (test1.rxfifo_full),
        .txfifo_empty (test1.txfifo_empty),
        .txfifo_full  (test1.txfifo_full)
    );

    csr_if m_csr_vif (
        .clk        (test1.clk),
        .rst_n      (test1.rst_n),
        .csr_rd_en  (test1.csr_rd_en),
        .csr_wr_en  (test1.csr_wr_en),
        .csr_addr   (test1.csr_addr),
        .csr_wdata  (test1.csr_wdata),
        .csr_rdata  (test1.csr_rdata)
    );

    function void set_spi_vif(string path);
        uvm_config_db#(virtual spi_if)::set(null, path, "spi_vif", m_spi_vif);
    endfunction

    function void set_csr_vif(string path);
        uvm_config_db#(virtual csr_if)::set(null, path, "csr_vif", m_csr_vif);
    endfunction

endinterface
`endif
