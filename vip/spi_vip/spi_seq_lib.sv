/******************************************************************************
 * SPI VIP Sequence Library
 * Description: Sequence library for SPI VIP
 ******************************************************************************/

`ifndef SPI_SEQ_LIB_SV
`define SPI_SEQ_LIB_SV

class spi_base_seq extends uvm_sequence#(spi_item);

    `uvm_object_utils(spi_base_seq)

    function new(string name = "spi_base_seq");
        super.new(name);
    endfunction

    virtual task pre_start();
        if(starting_phase != null) begin
            starting_phase.raise_objection(this, get_type_name());
        end
    endtask

    virtual task post_start();
        if(starting_phase != null) begin
            starting_phase.drop_objection(this, get_type_name());
        end
    endtask

endclass

class spi_wr_csr_seq extends spi_base_seq;

    `uvm_object_utils(spi_wr_csr_seq)

    rand bit [7:0] addr;
    rand bit [31:0] data;
    rand spi_lane_mode_t lane_mode;

    function new(string name = "spi_wr_csr_seq");
        super.new(name);
    endfunction

    virtual task body();
        spi_item trans;
        trans = spi_item::type_id::create("trans");

        start_item(trans);
        trans.opcode = CMD_WR_CSR;
        trans.addr = {24'h0, addr};
        trans.data = data;
        trans.lane_mode = lane_mode;
        trans.direction = DIR_WRITE;
        trans.burst_len = 1;
        finish_item(trans);
    endtask

endclass

class spi_rd_csr_seq extends spi_base_seq;

    `uvm_object_utils(spi_rd_csr_seq)

    rand bit [7:0] addr;
    rand spi_lane_mode_t lane_mode;

    bit [31:0] rdata;
    spi_status_t status;

    function new(string name = "spi_rd_csr_seq");
        super.new(name);
    endfunction

    virtual task body();
        spi_item trans;
        trans = spi_item::type_id::create("trans");

        start_item(trans);
        trans.opcode = CMD_RD_CSR;
        trans.addr = {24'h0, addr};
        trans.lane_mode = lane_mode;
        trans.direction = DIR_READ;
        trans.burst_len = 1;
        finish_item(trans);

        rdata = trans.data;
        status = trans.status;
    endtask

endclass

class spi_ahb_wr32_seq extends spi_base_seq;

    `uvm_object_utils(spi_ahb_wr32_seq)

    rand bit [31:0] addr;
    rand bit [31:0] data;
    rand spi_lane_mode_t lane_mode;

    function new(string name = "spi_ahb_wr32_seq");
        super.new(name);
    endfunction

    constraint addr_aligned {
        addr[1:0] == 2'b00;
    }

    virtual task body();
        spi_item trans;
        trans = spi_item::type_id::create("trans");

        start_item(trans);
        trans.opcode = CMD_AHB_WR32;
        trans.addr = addr;
        trans.data = data;
        trans.lane_mode = lane_mode;
        trans.direction = DIR_WRITE;
        trans.burst_len = 1;
        finish_item(trans);
    endtask

endclass

class spi_ahb_rd32_seq extends spi_base_seq;

    `uvm_object_utils(spi_ahb_rd32_seq)

    rand bit [31:0] addr;
    rand spi_lane_mode_t lane_mode;

    bit [31:0] rdata;
    spi_status_t status;

    function new(string name = "spi_ahb_rd32_seq");
        super.new(name);
    endfunction

    constraint addr_aligned {
        addr[1:0] == 2'b00;
    }

    virtual task body();
        spi_item trans;
        trans = spi_item::type_id::create("trans");

        start_item(trans);
        trans.opcode = CMD_AHB_RD32;
        trans.addr = addr;
        trans.lane_mode = lane_mode;
        trans.direction = DIR_READ;
        trans.burst_len = 1;
        finish_item(trans);

        rdata = trans.data;
        status = trans.status;
    endtask

endclass

class spi_ahb_wr_burst_seq extends spi_base_seq;

    `uvm_object_utils(spi_ahb_wr_burst_seq)

    rand bit [31:0] addr;
    rand bit [4:0] burst_len;
    rand spi_lane_mode_t lane_mode;

    rand bit [31:0] wdata_queue[$];

    function new(string name = "spi_ahb_wr_burst_seq");
        super.new(name);
    endfunction

    constraint burst_len_valid {
        burst_len inside {1, 4, 8, 16};
    }

    constraint addr_aligned {
        addr[1:0] == 2'b00;
    }

    constraint data_queue_size {
        wdata_queue.size() == burst_len;
    }

    constraint burst_bound {
        (addr[9:0] + 4*(burst_len-1)) < 1024;
    }

    virtual task body();
        spi_item trans;
        trans = spi_item::type_id::create("trans");

        start_item(trans);
        trans.opcode = CMD_AHB_WR_BURST;
        trans.addr = addr;
        trans.burst_len = burst_len;
        trans.lane_mode = lane_mode;
        trans.direction = DIR_WRITE;
        foreach(wdata_queue[i]) begin
            trans.wdata_queue.push_back(wdata_queue[i]);
        end
        finish_item(trans);
    endtask

endclass

class spi_ahb_rd_burst_seq extends spi_base_seq;

    `uvm_object_utils(spi_ahb_rd_burst_seq)

    rand bit [31:0] addr;
    rand bit [4:0] burst_len;
    rand spi_lane_mode_t lane_mode;

    bit [31:0] rdata_queue[$];
    spi_status_t status;

    function new(string name = "spi_ahb_rd_burst_seq");
        super.new(name);
    endfunction

    constraint burst_len_valid {
        burst_len inside {1, 4, 8, 16};
    }

    constraint addr_aligned {
        addr[1:0] == 2'b00;
    }

    constraint burst_bound {
        (addr[9:0] + 4*(burst_len-1)) < 1024;
    }

    virtual task body();
        spi_item trans;
        trans = spi_item::type_id::create("trans");

        start_item(trans);
        trans.opcode = CMD_AHB_RD_BURST;
        trans.addr = addr;
        trans.burst_len = burst_len;
        trans.lane_mode = lane_mode;
        trans.direction = DIR_READ;
        finish_item(trans);

        rdata_queue = trans.rdata_queue;
        status = trans.status;
    endtask

endclass

class spi_all_ops_seq extends spi_base_seq;

    `uvm_object_utils(spi_all_ops_seq)

    rand int num_iterations;

    function new(string name = "spi_all_ops_seq");
        super.new(name);
        num_iterations = 10;
    endfunction

    virtual task body();
        spi_wr_csr_seq wr_csr;
        spi_rd_csr_seq rd_csr;
        spi_ahb_wr32_seq wr32;
        spi_ahb_rd32_seq rd32;
        spi_ahb_wr_burst_seq wr_burst;
        spi_ahb_rd_burst_seq rd_burst;

        repeat(num_iterations) begin
            randcase
                1: begin
                    wr_csr = spi_wr_csr_seq::type_id::create("wr_csr");
                    wr_csr.randomize();
                    wr_csr.start(m_sequencer);
                end
                1: begin
                    rd_csr = spi_rd_csr_seq::type_id::create("rd_csr");
                    rd_csr.randomize();
                    rd_csr.start(m_sequencer);
                end
                1: begin
                    wr32 = spi_ahb_wr32_seq::type_id::create("wr32");
                    wr32.randomize();
                    wr32.start(m_sequencer);
                end
                1: begin
                    rd32 = spi_ahb_rd32_seq::type_id::create("rd32");
                    rd32.randomize();
                    rd32.start(m_sequencer);
                end
                1: begin
                    wr_burst = spi_ahb_wr_burst_seq::type_id::create("wr_burst");
                    wr_burst.randomize();
                    wr_burst.start(m_sequencer);
                end
                1: begin
                    rd_burst = spi_ahb_rd_burst_seq::type_id::create("rd_burst");
                    rd_burst.randomize();
                    rd_burst.start(m_sequencer);
                end
            endcase
        end
    endtask

endclass

`endif
