// APLC SPI Sequence Library
// Covers all RTM Testcase List requirements
`ifndef APLC_SPI_SEQ_LIB_SV
`define APLC_SPI_SEQ_LIB_SV

// Base sequence with common setup
class aplc_spi_seq_base extends uvm_sequence #(aplc_spi_item);

    `uvm_object_utils(aplc_spi_seq_base)
    `uvm_declare_p_sequencer(aplc_spi_sequencer)

    aplc_lane_mode_e m_lane_mode;

    function new(string name = "aplc_spi_seq_base");
        super.new(name);
        m_lane_mode = APLC_LANE_16BIT;
    endfunction

    virtual task pre_start();
        super.pre_start();
        if (starting_phase != null)
            starting_phase.raise_objection(this);
    endtask

    virtual task post_start();
        super.post_start();
        if (starting_phase != null)
            starting_phase.drop_objection(this);
    endtask

    // Send a single transaction and wait for response
    virtual task send_txn(ref aplc_spi_item txn);
        start_item(txn);
        if (!txn.randomize()) begin
            `uvm_error("APLC_SPI_SEQ", "Randomization failed")
        end
        txn.lane_mode = m_lane_mode;
        finish_item(txn);
    endtask

endclass

// WR_CSR sequence (TC_012, TC_013, TC_008~TC_011)
class aplc_spi_wr_csr_seq extends aplc_spi_seq_base;

    rand logic [7:0]  reg_addr;
    rand logic [31:0] wdata;

    `uvm_object_utils(aplc_spi_wr_csr_seq)

    function new(string name = "aplc_spi_wr_csr_seq");
        super.new(name);
    endfunction

    virtual task body();
        aplc_spi_item txn;
        txn = aplc_spi_item::type_id::create("txn");
        txn.opcode   = APLC_OP_WR_CSR;
        txn.reg_addr = reg_addr;
        txn.wdata    = new[1];
        txn.wdata[0] = wdata;
        send_txn(txn);
    endtask

endclass

// RD_CSR sequence (TC_014, TC_005, TC_006)
class aplc_spi_rd_csr_seq extends aplc_spi_seq_base;

    rand logic [7:0] reg_addr;

    `uvm_object_utils(aplc_spi_rd_csr_seq)

    function new(string name = "aplc_spi_rd_csr_seq");
        super.new(name);
    endfunction

    virtual task body();
        aplc_spi_item txn;
        txn = aplc_spi_item::type_id::create("txn");
        txn.opcode   = APLC_OP_RD_CSR;
        txn.reg_addr = reg_addr;
        send_txn(txn);
    endtask

endclass

// AHB_WR32 sequence (TC_015)
class aplc_spi_ahb_wr32_seq extends aplc_spi_seq_base;

    rand logic [31:0] addr;
    rand logic [31:0] wdata;

    `uvm_object_utils(aplc_spi_ahb_wr32_seq)

    function new(string name = "aplc_spi_ahb_wr32_seq");
        super.new(name);
    endfunction

    virtual task body();
        aplc_spi_item txn;
        txn = aplc_spi_item::type_id::create("txn");
        txn.opcode = APLC_OP_AHB_WR32;
        txn.addr   = addr;
        txn.wdata  = new[1];
        txn.wdata[0] = wdata;
        send_txn(txn);
    endtask

endclass

// AHB_RD32 sequence (TC_016)
class aplc_spi_ahb_rd32_seq extends aplc_spi_seq_base;

    rand logic [31:0] addr;

    `uvm_object_utils(aplc_spi_ahb_rd32_seq)

    function new(string name = "aplc_spi_ahb_rd32_seq");
        super.new(name);
    endfunction

    virtual task body();
        aplc_spi_item txn;
        txn = aplc_spi_item::type_id::create("txn");
        txn.opcode = APLC_OP_AHB_RD32;
        txn.addr   = addr;
        send_txn(txn);
    endtask

endclass

// AHB_WR_BURST sequence (TC_019)
class aplc_spi_ahb_wr_burst_seq extends aplc_spi_seq_base;

    rand logic [31:0]  addr;
    rand logic [4:0]   burst_len;
    rand logic [31:0]  wdata[];

    `uvm_object_utils(aplc_spi_ahb_wr_burst_seq)

    function new(string name = "aplc_spi_ahb_wr_burst_seq");
        super.new(name);
    endfunction

    constraint c_burst_len {
        burst_len inside {5'd1, 5'd4, 5'd8, 5'd16};
    }

    constraint c_wdata_size {
        wdata.size() == burst_len;
    }

    constraint c_addr_align {
        addr[1:0] == 2'b00;
    }

    virtual task body();
        aplc_spi_item txn;
        txn = aplc_spi_item::type_id::create("txn");
        txn.opcode    = APLC_OP_AHB_WR_BURST;
        txn.addr      = addr;
        txn.burst_len = burst_len;
        txn.wdata     = new[burst_len];
        foreach (wdata[i]) txn.wdata[i] = wdata[i];
        send_txn(txn);
    endtask

endclass

// AHB_RD_BURST sequence (TC_017, TC_018)
class aplc_spi_ahb_rd_burst_seq extends aplc_spi_seq_base;

    rand logic [31:0] addr;
    rand logic [4:0]  burst_len;

    `uvm_object_utils(aplc_spi_ahb_rd_burst_seq)

    function new(string name = "aplc_spi_ahb_rd_burst_seq");
        super.new(name);
    endfunction

    constraint c_burst_len {
        burst_len inside {5'd1, 5'd4, 5'd8, 5'd16};
    }

    constraint c_addr_align {
        addr[1:0] == 2'b00;
    }

    virtual task body();
        aplc_spi_item txn;
        txn = aplc_spi_item::type_id::create("txn");
        txn.opcode    = APLC_OP_AHB_RD_BURST;
        txn.addr      = addr;
        txn.burst_len = burst_len;
        send_txn(txn);
    endtask

endclass

// Bad opcode sequence (TC_020)
class aplc_spi_bad_opcode_seq extends aplc_spi_seq_base;

    rand logic [7:0] bad_opcode;

    `uvm_object_utils(aplc_spi_bad_opcode_seq)

    function new(string name = "aplc_spi_bad_opcode_seq");
        super.new(name);
    endfunction

    constraint c_bad_opcode {
        !(bad_opcode inside {8'h10, 8'h11, 8'h20, 8'h21, 8'h22, 8'h23});
    }

    virtual task body();
        aplc_spi_item txn;
        txn = aplc_spi_item::type_id::create("txn");
        txn.opcode = aplc_opcode_e'(bad_opcode);
        // Use AHB_RD32 as base but override opcode
        txn.addr   = 32'h10000000;
        send_txn(txn);
    endtask

endclass

// Frame abort sequence (TC_025, TC_040)
class aplc_spi_frame_abort_seq extends aplc_spi_seq_base;

    `uvm_object_utils(aplc_spi_frame_abort_seq)

    function new(string name = "aplc_spi_frame_abort_seq");
        super.new(name);
    endfunction

    virtual task body();
        aplc_spi_item txn;
        txn = aplc_spi_item::type_id::create("txn");
        txn.opcode     = APLC_OP_WR_CSR;
        txn.reg_addr   = 8'h04;
        txn.wdata      = new[1];
        txn.wdata[0]   = 32'h00000001;
        txn.frame_abort = 1'b1;
        send_txn(txn);
    endtask

endclass

// Non-aligned address sequence (TC_039)
class aplc_spi_align_err_seq extends aplc_spi_seq_base;

    rand logic [31:0] addr;

    `uvm_object_utils(aplc_spi_align_err_seq)

    function new(string name = "aplc_spi_align_err_seq");
        super.new(name);
    endfunction

    constraint c_addr_misalign {
        addr[1:0] != 2'b00;
    }

    virtual task body();
        aplc_spi_item txn;
        txn = aplc_spi_item::type_id::create("txn");
        txn.opcode = APLC_OP_AHB_RD32;
        txn.addr   = addr;
        send_txn(txn);
    endtask

endclass

// Bad burst_len sequence (TC_035)
class aplc_spi_bad_burst_seq extends aplc_spi_seq_base;

    rand logic [4:0] burst_len;

    `uvm_object_utils(aplc_spi_bad_burst_seq)

    function new(string name = "aplc_spi_bad_burst_seq");
        super.new(name);
    endfunction

    constraint c_bad_burst_len {
        !(burst_len inside {5'd1, 5'd4, 5'd8, 5'd16});
        burst_len > 0;
    }

    virtual task body();
        aplc_spi_item txn;
        txn = aplc_spi_item::type_id::create("txn");
        txn.opcode    = APLC_OP_AHB_RD_BURST;
        txn.addr      = 32'h10000000;
        txn.burst_len = burst_len;
        send_txn(txn);
    endtask

endclass

// Burst boundary error sequence (TC_044)
class aplc_spi_burst_bound_seq extends aplc_spi_seq_base;

    rand logic [31:0] addr;
    rand logic [4:0]  burst_len;

    `uvm_object_utils(aplc_spi_burst_bound_seq)

    function new(string name = "aplc_spi_burst_bound_seq");
        super.new(name);
    endfunction

    constraint c_burst_len {
        burst_len inside {5'd4, 5'd8, 5'd16};
    }

    constraint c_addr_cross_1kb {
        addr[1:0] == 2'b00;
        (addr[9:0] + 4 * (burst_len - 1)) >= 1024;
    }

    virtual task body();
        aplc_spi_item txn;
        txn = aplc_spi_item::type_id::create("txn");
        txn.opcode    = APLC_OP_AHB_RD_BURST;
        txn.addr      = addr;
        txn.burst_len = burst_len;
        send_txn(txn);
    endtask

endclass

// Lane mode switch sequence (TC_022, TC_023)
class aplc_spi_lane_switch_seq extends aplc_spi_seq_base;

    rand aplc_lane_mode_e new_lane;
    rand bit              during_txn;

    `uvm_object_utils(aplc_spi_lane_switch_seq)

    function new(string name = "aplc_spi_lane_switch_seq");
        super.new(name);
    endfunction

    virtual task body();
        aplc_spi_item txn;
        txn = aplc_spi_item::type_id::create("txn");
        txn.opcode     = APLC_OP_WR_CSR;
        txn.reg_addr   = 8'h04;
        txn.wdata      = new[1];
        txn.wdata[0]   = 32'h00000001;
        txn.lane_mode  = new_lane;
        if (during_txn)
            txn.lane_changed = 1'b1;
        send_txn(txn);
    endtask

endclass

// CSR access all registers sequence (TC_004, TC_050)
class aplc_spi_csr_access_seq extends aplc_spi_seq_base;

    `uvm_object_utils(aplc_spi_csr_access_seq)

    function new(string name = "aplc_spi_csr_access_seq");
        super.new(name);
    endfunction

    virtual task body();
        aplc_spi_item txn;

        // Write CTRL register
        txn = aplc_spi_item::type_id::create("txn");
        txn.opcode   = APLC_OP_WR_CSR;
        txn.reg_addr = 8'h04;
        txn.wdata    = new[1];
        txn.wdata[0] = 32'h00000001; // EN=1
        send_txn(txn);

        // Read back CTRL
        txn = aplc_spi_item::type_id::create("txn");
        txn.opcode   = APLC_OP_RD_CSR;
        txn.reg_addr = 8'h04;
        send_txn(txn);

        // Read VERSION
        txn = aplc_spi_item::type_id::create("txn");
        txn.opcode   = APLC_OP_RD_CSR;
        txn.reg_addr = 8'h00;
        send_txn(txn);

        // Read STATUS
        txn = aplc_spi_item::type_id::create("txn");
        txn.opcode   = APLC_OP_RD_CSR;
        txn.reg_addr = 8'h08;
        send_txn(txn);

        // Read LAST_ERR
        txn = aplc_spi_item::type_id::create("txn");
        txn.opcode   = APLC_OP_RD_CSR;
        txn.reg_addr = 8'h0C;
        send_txn(txn);

        // Read BURST_CNT
        txn = aplc_spi_item::type_id::create("txn");
        txn.opcode   = APLC_OP_RD_CSR;
        txn.reg_addr = 8'h10;
        send_txn(txn);
    endtask

endclass

// Full opcode traversal sequence (TC_021)
class aplc_spi_all_opcode_seq extends aplc_spi_seq_base;

    `uvm_object_utils(aplc_spi_all_opcode_seq)

    function new(string name = "aplc_spi_all_opcode_seq");
        super.new(name);
    endfunction

    virtual task body();
        aplc_spi_item txn;

        // WR_CSR
        txn = aplc_spi_item::type_id::create("txn");
        txn.opcode   = APLC_OP_WR_CSR;
        txn.reg_addr = 8'h04;
        txn.wdata    = new[1];
        txn.wdata[0] = 32'h00000001;
        send_txn(txn);

        // RD_CSR
        txn = aplc_spi_item::type_id::create("txn");
        txn.opcode   = APLC_OP_RD_CSR;
        txn.reg_addr = 8'h04;
        send_txn(txn);

        // AHB_WR32
        txn = aplc_spi_item::type_id::create("txn");
        txn.opcode = APLC_OP_AHB_WR32;
        txn.addr   = 32'h10000000;
        txn.wdata  = new[1];
        txn.wdata[0] = 32'hDEADBEEF;
        send_txn(txn);

        // AHB_RD32
        txn = aplc_spi_item::type_id::create("txn");
        txn.opcode = APLC_OP_AHB_RD32;
        txn.addr   = 32'h10000000;
        send_txn(txn);

        // AHB_WR_BURST x4
        txn = aplc_spi_item::type_id::create("txn");
        txn.opcode    = APLC_OP_AHB_WR_BURST;
        txn.addr      = 32'h10000000;
        txn.burst_len = 5'd4;
        txn.wdata     = new[4];
        foreach (txn.wdata[i]) txn.wdata[i] = 32'hA0000000 + i;
        send_txn(txn);

        // AHB_RD_BURST x4
        txn = aplc_spi_item::type_id::create("txn");
        txn.opcode    = APLC_OP_AHB_RD_BURST;
        txn.addr      = 32'h10000000;
        txn.burst_len = 5'd4;
        send_txn(txn);
    endtask

endclass

`endif
