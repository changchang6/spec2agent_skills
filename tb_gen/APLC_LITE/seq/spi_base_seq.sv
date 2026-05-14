`ifndef SPI_BASE_SEQ_SV
`define SPI_BASE_SEQ_SV

// AI gen: Base sequence for SPI agent - supports all 6 opcodes
class spi_base_seq extends uvm_sequence #(spi_transaction);

    rand bit [7:0]  opcode;
    rand bit [4:0]  burst_len;
    rand bit [7:0]  reg_addr;
    rand bit [31:0] addr;
    rand bit [31:0] wdata[];
    rand bit [1:0]  lane_mode;
    rand bit        en;
    rand bit        test_mode;

    `uvm_object_utils(spi_base_seq)
    `uvm_declare_p_sequencer(spi_sequencer)

    function new(string name = "spi_base_seq");
        super.new(name);
        en        = 1'b1;
        test_mode = 1'b1;
        lane_mode = `LANE_MODE_16BIT;
    endfunction

    // AI gen: Constraint - legal opcode values
    constraint c_opcode {
        opcode inside {`OPC_WR_CSR, `OPC_RD_CSR, `OPC_AHB_WR32,
                       `OPC_AHB_RD32, `OPC_AHB_WR_BURST, `OPC_AHB_RD_BURST};
    }

    // AI gen: Constraint - legal burst_len values
    constraint c_burst_len {
        burst_len inside {5'd1, 5'd4, 5'd8, 5'd16};
    }

    // AI gen: Constraint - wdata size based on opcode
    constraint c_wdata_size {
        if (opcode == `OPC_WR_CSR) wdata.size() == 1;
        else if (opcode == `OPC_AHB_WR32) wdata.size() == 1;
        else if (opcode == `OPC_AHB_WR_BURST) wdata.size() == burst_len;
        else wdata.size() == 0;
    }

    // AI gen: Constraint - CSR addr range
    constraint c_csr_addr {
        if (opcode inside {`OPC_WR_CSR, `OPC_RD_CSR})
            reg_addr < 8'h40;
    }

    // AI gen: Constraint - AHB addr alignment
    constraint c_ahb_addr_align {
        if (opcode inside {`OPC_AHB_WR32, `OPC_AHB_RD32,
                           `OPC_AHB_WR_BURST, `OPC_AHB_RD_BURST})
            addr[1:0] == 2'b00;
    }

    virtual task body();
        spi_transaction tr;
        int wdata_size;
        tr = spi_transaction::type_id::create("tr");
        start_item(tr);
        if (!tr.randomize()) begin
            `uvm_fatal(get_type_name(), "Randomization failed")
        end
        // AI gen: Copy sequence fields to transaction
        tr.opcode     = this.opcode;
        tr.burst_len  = this.burst_len;
        tr.reg_addr   = this.reg_addr;
        tr.addr       = this.addr;
        tr.lane_mode  = this.lane_mode;
        tr.en         = this.en;
        tr.test_mode  = this.test_mode;
        // Copy wdata if present
        wdata_size = this.wdata.size();
        if (wdata_size > 0) begin
            tr.wdata = new[wdata_size];
            foreach (this.wdata[i]) tr.wdata[i] = this.wdata[i];
        end
        finish_item(tr);
    endtask

endclass : spi_base_seq

`endif
