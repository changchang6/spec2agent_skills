`ifndef TEST1_RM_SV
`define TEST1_RM_SV

class test1_rm extends uvm_component;
    `uvm_component_utils(test1_rm)
	
	uvm_blocking_get_port #(spi_transaction) spi_port_in[SPI_NUM];
    uvm_blocking_get_port #(csr_transaction) csr_port_in[CSR_NUM];

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

	extern virtual function void build_phase(uvm_phase phase);
	extern virtual task main_phase(uvm_phase phase);
endclass : test1_rm

function void test1_rm::build_phase(uvm_phase phase);
    super.build_phase(phase);
	foreach(spi_port_in[i]) begin
            spi_port_in[i] = new($sformatf("spi_port_in[%0d]", i), this);
        end
        foreach(csr_port_in[i]) begin
            csr_port_in[i] = new($sformatf("csr_port_in[%0d]", i), this);
        end
endfunction

virtual task test1_rm::main_phase(my_transaction tr);
	super.main_phase();
endfunction

`endif 