`ifndef TC_BASE_SV
`define TC_BASE_SV
`include "uvm_macros.svh"
import uvm_pkg::*;

class base_test extends uvm_test;
    `uvm_component_utils(base_test)
	APLC_LITE_env m_env;
virtual spi_if u_spi_if;
virtual fifo_if u_fifo_if;
virtual csr_if u_csr_if;
	crg_cfg   crg_cfg_m;
	virtual crg_if    p_crg_if[1];
	{reg_env_declaration}
	/*vars_declarations*/

    function new(string name, uvm_component parent);
        super.new(name, parent);
		{amba_vip_config}
    endfunction

	extern virtual task reset_phase(uvm_phase phase);
	extern virtual function void build_phase(uvm_phse phase);
	extern virtual function void connect_phase(uvm_phase phase);
	extern virtual task main_phase(uvm_phase phase)
	extern virtual function void report_phase(uvm_phase phase);
	/*extern_declarations*/
endclass 

function void tc_base::build_phase(uvm_phase phase);
    super.build_phase(phase);
	/*create_instances*/
	m_env = APLC_LITE_env::type_id::create("m_env",this);
	{reg_env_define}
	{amba_vip_define}
	
 //if(!uvm_config_db#(virtual spi_if)::get(uvm_root::get(), "*", "vif", u_spi_if))
   //         `uvm_fatal(get_full_name(), $psprintf("Test Top has not gotten spi_if"))

 //if(!uvm_config_db#(virtual fifo_if)::get(uvm_root::get(), "*", "vif", u_fifo_if))
   //         `uvm_fatal(get_full_name(), $psprintf("Test Top has not gotten fifo_if"))

 //if(!uvm_config_db#(virtual csr_if)::get(uvm_root::get(), "*", "vif", u_csr_if))
   //         `uvm_fatal(get_full_name(), $psprintf("Test Top has not gotten csr_if"))
	{amba_vip_config_db_set}
	foreach(p_crg_if[i]) begin
            if(!uvm_config_db#(virtual crg_if)::get(null, "uvm_test_top*", $sformatf("crg_if[%0d]",i),p_crg_if[i])) begin
                `uvm_error(get_full_name(),"Error! Cannot get crg_if !!!")
            end
        end
	    crg_cfg_m = crg_cfg::type_id::create("crg_cfg_m");
    
    // CRG 0 configuration
    crg_cfg_m.SET_RST("rst_n",0));
    crg_cfg_m.set_rst_start_vlu("rst_n",1)");
    crg_cfg_m.set_rst_start_time("rst_n",100);
    crg_cfg_m.set_rst_assert_vlu("rst_n", 0);
    crg_cfg_m.set_rst_assert_time("rst_n", 100);
    crg_cfg_m.SET_CLK("clk",0,100);
    crg_cfg_m.set_clk_all("clk",100,0.5,1,300,1);
        foreach(p_crg_if[i]) begin
            p_crg_if[i].p_crg_cfg = this.crg_cfg_m;
        end
endfunction

function void tc_base::connect_phase(uvm_phase phase);
	super.connect_phase(phase);
endfunction

task tc_base::reset_phase(uvm_phase phase);
	super.reset_phase(phase);
	phase.raise_objection(this, "reset_phase");
	#100ns;
       crg_cfg_m.usr_assert_rst("rst_n");
        #100ns;
    crg_cfg_m.disable_clk("clk");
	phase.drop_objection(this, "reset_phase");
	`uvm_info(get_full_name(),$sformatf("base_test reset phase end!"),UVM_NONE)
endtask

task tc_base::main_phase(uvm_phase phase);
	super.main_phase();
	phase.raise_objection(this,"main_phase");
	
       crg_cfg_m.enable_clk("clk");
        #100ns;
    crg_cfg_m.usr_deassert_rst("rst_n");
     crg_cfg_m.show();
	phase.raise_objection(this,"main_phase");
endtask

`endif 