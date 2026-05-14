`ifndef APLC_LITE_SCOREBOARD_SV
`define APLC_LITE_SCOREBOARD_SV

class APLC_LITE_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(APLC_LITE_scoreboard)

	csr_transaction csr_exp_arr[$]
    fifo_transaction fifo_exp_arr[$]
    uvm_blocking_get_port #(csr_transaction) csr_exp_port[CSR_NUM];
    uvm_blocking_get_port #(csr_transaction) csr_act_port[CSR_NUM];
    uvm_blocking_get_port #(fifo_transaction) fifo_exp_port[FIFO_NUM];
    uvm_blocking_get_port #(fifo_transaction) fifo_act_port[FIFO_NUM];

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
		foreach(csr_exp_port[i]) begin
           csr_exp_port[i] = new($sformatf("csr_exp_port[%0d]", i), this);
        end
        foreach(csr_act_port[i]) begin
            csr_act_port[i] = new($sformatf("csr_act_port[%0d]", i), this);
        end
        foreach(fifo_exp_port[i]) begin
           fifo_exp_port[i] = new($sformatf("fifo_exp_port[%0d]", i), this);
        end
        foreach(fifo_act_port[i]) begin
            fifo_act_port[i] = new($sformatf("fifo_act_port[%0d]", i), this);
        end
    endfunction

	virtual task main_phase(uvm_phase phase);
		csr_transaction csr_exp_tr[FIFO_NUM];
        csr_transaction csr_act_tr[FIFO_NUM];
        csr_transaction csr_tmp_tr[FIFO_NUM];
        bit csr_result[FIFO_NUM];
        fifo_transaction fifo_exp_tr[FIFO_NUM];
        fifo_transaction fifo_act_tr[FIFO_NUM];
        fifo_transaction fifo_tmp_tr[FIFO_NUM];
        bit fifo_result[FIFO_NUM];
        super.main_phase(phase);
        // Compare expected and actual data
        fork
        for (int i = 0; i < CSR_NUM; i++) begin
            automatic int idx = i;
            fork
                begin
                    forever begin
                        csr_exp_port[idx].get(csr_exp_tr[idx]);
                        csr_exp_arr.push_back(csr_exp_tr[idx]);
                    end
                end
                begin
                    forever begin
                        csr_act_port[idx].get(csr_act_tr[idx]);
                        if(csr_exp_arr.size() > 0) begin
                            csr_tmp_tr[idx] = csr_exp_arr.pop_front();
                            csr_result[idx] = csr_exp_tr[idx].compare(csr_tmp_tr[idx]);
                            if(csr_result[idx]) begin
                                `uvm_info(get_type_name(), $psprintf("Compare csr_result success !!!"),UVM_LOW)
                            end else begin
                                `uvm_error(get_type_name(), $psprintf("Compare csr_result failed !!!"))
                            end
                        end else begin
                            `uvm_error(get_type_name(), $psprintf("Received result from DUT, while Exp queue is empty !!!"))
                        end
                    end
                end
            join_none
        end
        for (int i = 0; i < FIFO_NUM; i++) begin
            automatic int idx = i;
            fork
                begin
                    forever begin
                        fifo_exp_port[idx].get(fifo_exp_tr[idx]);
                        fifo_exp_arr.push_back(fifo_exp_tr[idx]);
                    end
                end
                begin
                    forever begin
                        fifo_act_port[idx].get(fifo_act_tr[idx]);
                        if(fifo_exp_arr.size() > 0) begin
                            fifo_tmp_tr[idx] = fifo_exp_arr.pop_front();
                            fifo_result[idx] = fifo_exp_tr[idx].compare(fifo_tmp_tr[idx]);
                            if(fifo_result[idx]) begin
                                `uvm_info(get_type_name(), $psprintf("Compare fifo_result success !!!"),UVM_LOW)
                            end else begin
                                `uvm_error(get_type_name(), $psprintf("Compare fifo_result failed !!!"))
                            end
                        end else begin
                            `uvm_error(get_type_name(), $psprintf("Received result from DUT, while Exp queue is empty !!!"))
                        end
                    end
                end
            join_none
        end
        join
	endtask
	
endclass : APLC_LITE_scoreboard

`endif 