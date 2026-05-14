`timescale 1ns/1ps

module tb_top;
	crg_if u_crg_if();
    
     // bind test1 crg_if u_crg_if (
     //);
	//spi_if u_spi_if(.clk(u_crg_if.clks[0]),.rst_n(u_crg_if.rsts[0]));
  //csr_if u_csr_if(.clk(u_crg_if.clks[0]),.rst_n(u_crg_if.rsts[0]));
	{amba_vip_if_declarations}

	/*AUTOINPUT*/
	/*AUTOOUTPUT*/
	/*AUTOINOUT*/
	
	/* demo AUTO_TEMPLATE(
		.\(.*\) (@"(upcase (symbol-name `\1))"[]),
	);
	*/
	test1 #(/*AUTOINSTPARAM*/)
	u_dut (/*AUTOINST*/);
	
	{amba_vip_if_connect}
	assign u_dut.clk = u_crg_if.clks[0];
   assign u_dut.rst_n = u_crg_if.rsts[0];
   assign u_dut.csr_rd_en = u_crg_if.clks[0];
   assign u_dut.csr_wr_en = u_crg_if.rsts[0];
	bind test1 if_harness harness(.*);
	initial begin
		run_test();
	end
	
	initial begin
		u_dut.harness.set_spi_vif("uvm_test_top.m_env.spi_agt[0].m_driver");
   u_dut.harness.set_spi_vif("uvm_test_top.m_env.spi_agt[0].m_monitor");
   u_dut.harness.set_csr_vif("uvm_test_top.m_env.spi_agt[0].m_driver");
   u_dut.harness.set_csr_vif("uvm_test_top.m_env.spi_agt[0].m_monitor");
   u_dut.harness.set_spi_vif("uvm_test_top.m_env.csr_agt[0].m_driver");
   u_dut.harness.set_spi_vif("uvm_test_top.m_env.csr_agt[0].m_monitor");
   u_dut.harness.set_csr_vif("uvm_test_top.m_env.csr_agt[0].m_driver");
   u_dut.harness.set_csr_vif("uvm_test_top.m_env.csr_agt[0].m_monitor");
	end
	
	initial begin
	    uvm_config_db#(virtual crg_if)::set(null, "uvm_test_top*", "crg_if[0]", u_crg_if);
	//   uvm_config_db#(virtual spi_if)::set(uvm_root::get(), "*", "vif", u_spi_if);
   //   uvm_config_db#(virtual csr_if)::set(uvm_root::get(), "*", "vif", u_csr_if);
	{amba_if_config}
	end
endmodule

// Local Variables:
// verilog-library-directories:("." "/home/path/")
// verilog-library-files: ("demo.v")
// End:
