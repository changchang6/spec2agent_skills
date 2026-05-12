`ifndef APLC_SPI_SEQ_LIB_SV
`define APLC_SPI_SEQ_LIB_SV

class aplc_spi_base_seq extends uvm_sequence #(aplc_spi_item);

    `uvm_object_utils(aplc_spi_base_seq)
    `uvm_declare_p_sequencer(aplc_spi_sequencer)

    function new(string name = "aplc_spi_base_seq");
        super.new(name);
    endfunction

    virtual task pre_start();
        super.pre_start();
    endtask

    virtual task body();
        `uvm_fatal(get_type_name(), "Base sequence body should not be called directly")
    endtask

endclass

class aplc_spi_wr_csr_seq extends aplc_spi_base_seq;

    `uvm_object_utils(aplc_spi_wr_csr_seq)

    rand bit [7:0]  reg_addr;
    rand bit [31:0] wdata;
    rand bit [1:0]  lane_mode;

    constraint reg_addr_legal_c {
        reg_addr < 8'h40;
    }

    function new(string name = "aplc_spi_wr_csr_seq");
        super.new(name);
    endfunction

    virtual task body();
        aplc_spi_item item;
        item = aplc_spi_item::type_id::create("item");
        start_item(item);
        item.opcode    = APLC_SPI_WR_CSR;
        item.reg_addr  = reg_addr;
        item.wdata     = new[1];
        item.wdata[0]  = wdata;
        item.lane_mode = lane_mode;
        finish_item(item);
    endtask

endclass

class aplc_spi_rd_csr_seq extends aplc_spi_base_seq;

    `uvm_object_utils(aplc_spi_rd_csr_seq)

    rand bit [7:0]  reg_addr;
    rand bit [1:0]  lane_mode;

    constraint reg_addr_legal_c {
        reg_addr < 8'h40;
    }

    function new(string name = "aplc_spi_rd_csr_seq");
        super.new(name);
    endfunction

    virtual task body();
        aplc_spi_item item;
        item = aplc_spi_item::type_id::create("item");
        start_item(item);
        item.opcode    = APLC_SPI_RD_CSR;
        item.reg_addr  = reg_addr;
        item.lane_mode = lane_mode;
        finish_item(item);
    endtask

endclass

class aplc_spi_ahb_wr32_seq extends aplc_spi_base_seq;

    `uvm_object_utils(aplc_spi_ahb_wr32_seq)

    rand bit [31:0] addr;
    rand bit [31:0] wdata;
    rand bit [1:0]  lane_mode;

    constraint addr_align_c {
        addr[1:0] == 2'b00;
    }

    function new(string name = "aplc_spi_ahb_wr32_seq");
        super.new(name);
    endfunction

    virtual task body();
        aplc_spi_item item;
        item = aplc_spi_item::type_id::create("item");
        start_item(item);
        item.opcode    = APLC_SPI_AHB_WR32;
        item.addr      = addr;
        item.wdata     = new[1];
        item.wdata[0]  = wdata;
        item.lane_mode = lane_mode;
        finish_item(item);
    endtask

endclass

class aplc_spi_ahb_rd32_seq extends aplc_spi_base_seq;

    `uvm_object_utils(aplc_spi_ahb_rd32_seq)

    rand bit [31:0] addr;
    rand bit [1:0]  lane_mode;

    constraint addr_align_c {
        addr[1:0] == 2'b00;
    }

    function new(string name = "aplc_spi_ahb_rd32_seq");
        super.new(name);
    endfunction

    virtual task body();
        aplc_spi_item item;
        item = aplc_spi_item::type_id::create("item");
        start_item(item);
        item.opcode    = APLC_SPI_AHB_RD32;
        item.addr      = addr;
        item.lane_mode = lane_mode;
        finish_item(item);
    endtask

endclass

class aplc_spi_ahb_wr_burst_seq extends aplc_spi_base_seq;

    `uvm_object_utils(aplc_spi_ahb_wr_burst_seq)

    rand bit [31:0] addr;
    rand bit [4:0]  burst_len;
    rand bit [1:0]  lane_mode;

    constraint addr_align_c {
        addr[1:0] == 2'b00;
    }

    constraint burst_len_legal_c {
        burst_len inside {1, 4, 8, 16};
    }

    function new(string name = "aplc_spi_ahb_wr_burst_seq");
        super.new(name);
    endfunction

    virtual task body();
        aplc_spi_item item;
        item = aplc_spi_item::type_id::create("item");
        start_item(item);
        item.opcode    = APLC_SPI_AHB_WR_BURST;
        item.addr      = addr;
        item.burst_len = burst_len;
        item.lane_mode = lane_mode;
        item.wdata     = new[burst_len];
        foreach (item.wdata[i]) item.wdata[i] = $urandom_range(32'h0, 32'hFFFFFFFF);
        finish_item(item);
    endtask

endclass

class aplc_spi_ahb_rd_burst_seq extends aplc_spi_base_seq;

    `uvm_object_utils(aplc_spi_ahb_rd_burst_seq)

    rand bit [31:0] addr;
    rand bit [4:0]  burst_len;
    rand bit [1:0]  lane_mode;

    constraint addr_align_c {
        addr[1:0] == 2'b00;
    }

    constraint burst_len_legal_c {
        burst_len inside {1, 4, 8, 16};
    }

    function new(string name = "aplc_spi_ahb_rd_burst_seq");
        super.new(name);
    endfunction

    virtual task body();
        aplc_spi_item item;
        item = aplc_spi_item::type_id::create("item");
        start_item(item);
        item.opcode    = APLC_SPI_AHB_RD_BURST;
        item.addr      = addr;
        item.burst_len = burst_len;
        item.lane_mode = lane_mode;
        finish_item(item);
    endtask

endclass

class aplc_spi_bad_opcode_seq extends aplc_spi_base_seq;

    `uvm_object_utils(aplc_spi_bad_opcode_seq)

    rand bit [7:0]  bad_opcode;
    rand bit [1:0]  lane_mode;

    constraint bad_opcode_c {
        !(bad_opcode inside {8'h10, 8'h11, 8'h20, 8'h21, 8'h22, 8'h23});
    }

    function new(string name = "aplc_spi_bad_opcode_seq");
        super.new(name);
    endfunction

    virtual task body();
        aplc_spi_item item;
        item = aplc_spi_item::type_id::create("item");
        start_item(item);
        item.opcode       = APLC_SPI_WR_CSR;
        item.inject_error = 1'b1;
        item.error_opcode = bad_opcode;
        item.lane_mode    = lane_mode;
        finish_item(item);
    endtask

endclass

class aplc_spi_bad_reg_seq extends aplc_spi_base_seq;

    `uvm_object_utils(aplc_spi_bad_reg_seq)

    rand bit [7:0]  bad_reg_addr;
    rand bit [1:0]  lane_mode;

    constraint bad_reg_addr_c {
        bad_reg_addr >= 8'h40;
    }

    function new(string name = "aplc_spi_bad_reg_seq");
        super.new(name);
    endfunction

    virtual task body();
        aplc_spi_item item;
        item = aplc_spi_item::type_id::create("item");
        start_item(item);
        item.opcode         = APLC_SPI_RD_CSR;
        item.inject_error   = 1'b1;
        item.error_reg_addr = bad_reg_addr;
        item.lane_mode      = lane_mode;
        finish_item(item);
    endtask

endclass

class aplc_spi_align_err_seq extends aplc_spi_base_seq;

    `uvm_object_utils(aplc_spi_align_err_seq)

    rand bit [31:0] bad_addr;
    rand bit [1:0]  lane_mode;

    constraint bad_addr_c {
        bad_addr[1:0] != 2'b00;
    }

    function new(string name = "aplc_spi_align_err_seq");
        super.new(name);
    endfunction

    virtual task body();
        aplc_spi_item item;
        item = aplc_spi_item::type_id::create("item");
        start_item(item);
        item.opcode    = APLC_SPI_AHB_WR32;
        item.inject_error = 1'b1;
        item.error_addr = bad_addr;
        item.lane_mode = lane_mode;
        finish_item(item);
    endtask

endclass

class aplc_spi_bad_burst_len_seq extends aplc_spi_base_seq;

    `uvm_object_utils(aplc_spi_bad_burst_len_seq)

    rand bit [4:0]  bad_burst_len;
    rand bit [1:0]  lane_mode;

    constraint bad_burst_len_c {
        !(bad_burst_len inside {1, 4, 8, 16});
        bad_burst_len > 0;
    }

    function new(string name = "aplc_spi_bad_burst_len_seq");
        super.new(name);
    endfunction

    virtual task body();
        aplc_spi_item item;
        item = aplc_spi_item::type_id::create("item");
        start_item(item);
        item.opcode          = APLC_SPI_AHB_WR_BURST;
        item.inject_error    = 1'b1;
        item.error_burst_len = bad_burst_len;
        item.lane_mode       = lane_mode;
        finish_item(item);
    endtask

endclass

class aplc_spi_not_in_test_seq extends aplc_spi_base_seq;

    `uvm_object_utils(aplc_spi_not_in_test_seq)

    rand bit [1:0] lane_mode;

    function new(string name = "aplc_spi_not_in_test_seq");
        super.new(name);
    endfunction

    virtual task body();
        aplc_spi_item item;
        item = aplc_spi_item::type_id::create("item");
        start_item(item);
        item.opcode    = APLC_SPI_RD_CSR;
        item.reg_addr  = 8'h00;
        item.lane_mode = lane_mode;
        finish_item(item);
    endtask

endclass

class aplc_spi_random_seq extends aplc_spi_base_seq;

    `uvm_object_utils(aplc_spi_random_seq)

    rand int unsigned n_items = 10;

    constraint n_items_c {
        n_items inside {[5:50]};
    }

    function new(string name = "aplc_spi_random_seq");
        super.new(name);
    endfunction

    virtual task body();
        for (int i = 0; i < n_items; i++) begin
            aplc_spi_item item;
            item = aplc_spi_item::type_id::create("item");
            start_item(item);
            if (!item.randomize()) begin
                `uvm_error(get_type_name(), "Failed to randomize item")
            end
            finish_item(item);
        end
    endtask

endclass

`endif
