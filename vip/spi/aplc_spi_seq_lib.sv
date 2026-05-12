`ifndef APLC_SPI_SEQ_LIB_SV
`define APLC_SPI_SEQ_LIB_SV

class aplc_spi_seq_base extends uvm_sequence #(aplc_spi_item);
    `uvm_object_utils(aplc_spi_seq_base)
    `uvm_declare_p_sequencer(aplc_spi_sequencer)

    function new(string name = "aplc_spi_seq_base");
        super.new(name);
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
endclass

class aplc_wr_csr_seq extends aplc_spi_seq_base;
    `uvm_object_utils(aplc_wr_csr_seq)

    rand logic [7:0]  reg_addr;
    rand logic [31:0] wdata;

    constraint c_addr { reg_addr < 8'h40; }

    function new(string name = "aplc_wr_csr_seq");
        super.new(name);
    endfunction

    virtual task body();
        aplc_spi_item item;
        item = aplc_spi_item::type_id::create("item");
        start_item(item);
        if (!item.randomize() with {
            opcode    == APLC_OP_WR_CSR;
            this.reg_addr == reg_addr;
            this.wdata   == wdata;
        }) `uvm_error("SEQ", "Randomize failed")
        finish_item(item);
    endtask
endclass

class aplc_rd_csr_seq extends aplc_spi_seq_base;
    `uvm_object_utils(aplc_rd_csr_seq)

    rand logic [7:0] reg_addr;

    constraint c_addr { reg_addr < 8'h40; }

    function new(string name = "aplc_rd_csr_seq");
        super.new(name);
    endfunction

    virtual task body();
        aplc_spi_item item;
        item = aplc_spi_item::type_id::create("item");
        start_item(item);
        if (!item.randomize() with {
            opcode       == APLC_OP_RD_CSR;
            this.reg_addr == reg_addr;
        }) `uvm_error("SEQ", "Randomize failed")
        finish_item(item);
    endtask
endclass

class aplc_ahb_wr32_seq extends aplc_spi_seq_base;
    `uvm_object_utils(aplc_ahb_wr32_seq)

    rand logic [31:0] addr;
    rand logic [31:0] wdata;

    constraint c_align { addr[1:0] == 2'b00; }

    function new(string name = "aplc_ahb_wr32_seq");
        super.new(name);
    endfunction

    virtual task body();
        aplc_spi_item item;
        item = aplc_spi_item::type_id::create("item");
        start_item(item);
        if (!item.randomize() with {
            opcode     == APLC_OP_AHB_WR32;
            this.addr  == addr;
            this.wdata == wdata;
        }) `uvm_error("SEQ", "Randomize failed")
        finish_item(item);
    endtask
endclass

class aplc_ahb_rd32_seq extends aplc_spi_seq_base;
    `uvm_object_utils(aplc_ahb_rd32_seq)

    rand logic [31:0] addr;

    constraint c_align { addr[1:0] == 2'b00; }

    function new(string name = "aplc_ahb_rd32_seq");
        super.new(name);
    endfunction

    virtual task body();
        aplc_spi_item item;
        item = aplc_spi_item::type_id::create("item");
        start_item(item);
        if (!item.randomize() with {
            opcode    == APLC_OP_AHB_RD32;
            this.addr == addr;
        }) `uvm_error("SEQ", "Randomize failed")
        finish_item(item);
    endtask
endclass

class aplc_ahb_wr_burst_seq extends aplc_spi_seq_base;
    `uvm_object_utils(aplc_ahb_wr_burst_seq)

    rand logic [31:0]  addr;
    rand logic [4:0]   burst_len;

    constraint c_align { addr[1:0] == 2'b00; }
    constraint c_burst { burst_len inside {5'd4, 5'd8, 5'd16}; }

    function new(string name = "aplc_ahb_wr_burst_seq");
        super.new(name);
    endfunction

    virtual task body();
        aplc_spi_item item;
        item = aplc_spi_item::type_id::create("item");
        start_item(item);
        if (!item.randomize() with {
            opcode         == APLC_OP_AHB_WR_BURST;
            this.addr      == addr;
            this.burst_len == burst_len;
        }) `uvm_error("SEQ", "Randomize failed")
        finish_item(item);
    endtask
endclass

class aplc_ahb_rd_burst_seq extends aplc_spi_seq_base;
    `uvm_object_utils(aplc_ahb_rd_burst_seq)

    rand logic [31:0] addr;
    rand logic [4:0]  burst_len;

    constraint c_align { addr[1:0] == 2'b00; }
    constraint c_burst { burst_len inside {5'd4, 5'd8, 5'd16}; }

    function new(string name = "aplc_rd_burst_seq");
        super.new(name);
    endfunction

    virtual task body();
        aplc_spi_item item;
        item = aplc_spi_item::type_id::create("item");
        start_item(item);
        if (!item.randomize() with {
            opcode         == APLC_OP_AHB_RD_BURST;
            this.addr      == addr;
            this.burst_len == burst_len;
        }) `uvm_error("SEQ", "Randomize failed")
        finish_item(item);
    endtask
endclass

class aplc_bad_opcode_seq extends aplc_spi_seq_base;
    `uvm_object_utils(aplc_bad_opcode_seq)

    rand logic [7:0] bad_opcode;

    constraint c_bad { !(bad_opcode inside {8'h10, 8'h11, 8'h20, 8'h21, 8'h22, 8'h23}); }

    function new(string name = "aplc_bad_opcode_seq");
        super.new(name);
    endfunction

    virtual task body();
        aplc_spi_item item;
        item = aplc_spi_item::type_id::create("item");
        start_item(item);
        item.opcode    = aplc_opcode_e'(bad_opcode);
        item.reg_addr  = 8'h00;
        item.addr      = 32'h0;
        item.wdata     = 32'h0;
        item.burst_len = 5'd0;
        finish_item(item);
    endtask
endclass

class aplc_frame_abort_seq extends aplc_spi_seq_base;
    `uvm_object_utils(aplc_frame_abort_seq)

    function new(string name = "aplc_frame_abort_seq");
        super.new(name);
    endfunction

    virtual task body();
        aplc_spi_item item;
        item = aplc_spi_item::type_id::create("item");
        start_item(item);
        if (!item.randomize() with {
            opcode == APLC_OP_WR_CSR;
        }) `uvm_error("SEQ", "Randomize failed")
        item.frame_abort = 1;
        finish_item(item);
    endtask
endclass

class aplc_smoke_seq extends aplc_spi_seq_base;
    `uvm_object_utils(aplc_smoke_seq)

    function new(string name = "aplc_smoke_seq");
        super.new(name);
    endfunction

    virtual task body();
        aplc_spi_item item;

        // WR_CSR to CTRL register (addr 0x04)
        item = aplc_spi_item::type_id::create("wr_csr");
        start_item(item);
        item.opcode    = APLC_OP_WR_CSR;
        item.reg_addr  = 8'h04;
        item.wdata     = 32'h0000_000F;
        item.burst_len = 5'd0;
        item.lane_mode = APLC_LANE_16BIT;
        finish_item(item);

        // RD_CSR from VERSION register (addr 0x00)
        item = aplc_spi_item::type_id::create("rd_csr");
        start_item(item);
        item.opcode    = APLC_OP_RD_CSR;
        item.reg_addr  = 8'h00;
        item.burst_len = 5'd0;
        item.lane_mode = APLC_LANE_16BIT;
        finish_item(item);

        // AHB_WR32
        item = aplc_spi_item::type_id::create("ahb_wr");
        start_item(item);
        item.opcode    = APLC_OP_AHB_WR32;
        item.addr      = 32'h0000_1000;
        item.wdata     = 32'hDEAD_BEEF;
        item.burst_len = 5'd0;
        item.lane_mode = APLC_LANE_16BIT;
        finish_item(item);

        // AHB_RD32 - read back
        item = aplc_spi_item::type_id::create("ahb_rd");
        start_item(item);
        item.opcode    = APLC_OP_AHB_RD32;
        item.addr      = 32'h0000_1000;
        item.burst_len = 5'd0;
        item.lane_mode = APLC_LANE_16BIT;
        finish_item(item);
    endtask
endclass

`endif
