`ifndef TEST1_SCOREBOARD_SV
`define TEST1_SCOREBOARD_SV

class test1_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(test1_scoreboard)

	
    

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
		
    endfunction

	virtual task main_phase(uvm_phase phase);
		super.main_phase(phase);
        // Compare expected and actual data
        fork
        join
	endtask
	
endclass : test1_scoreboard

`endif 