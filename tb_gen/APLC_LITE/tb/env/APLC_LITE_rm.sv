`ifndef APLC_LITE_RM_SV
`define APLC_LITE_RM_SV

class APLC_LITE_rm extends uvm_component;
    `uvm_component_utils(APLC_LITE_rm)
	
	uvm_blocking_get_port #(spi_transaction) spi_port_in[SPI_NUM];
    uvm_analysis_port #(csr_transaction) csr_port_out[CSR_NUM];
    uvm_analysis_port #(fifo_transaction) fifo_port_out[FIFO_NUM];

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

	extern virtual function void build_phase(uvm_phase phase);
	extern virtual task main_phase(uvm_phase phase);
endclass : APLC_LITE_rm

function void APLC_LITE_rm::build_phase(uvm_phase phase);
    super.build_phase(phase);
	foreach(spi_port_in[i]) begin
            spi_port_in[i] = new($sformatf("spi_port_in[%0d]", i), this);
        end
        foreach(csr_port_out[i]) begin
            csr_port_out[i] = new($sformatf("csr_port_out[%0d]", i), this);
        end
        foreach(fifo_port_out[i]) begin
            fifo_port_out[i] = new($sformatf("fifo_port_out[%0d]", i), this);
        end
endfunction

virtual task APLC_LITE_rm::main_phase(my_transaction tr);
	super.main_phase();
endfunction

`endif 