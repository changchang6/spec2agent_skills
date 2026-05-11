`ifndef SPI_SEQ_LIB_SV
`define SPI_SEQ_LIB_SV

class spi_base_seq extends uvm_sequence#(spi_drv_item);

  `uvm_object_utils(spi_base_seq)
  `uvm_declare_p_sequencer(spi_sequencer)

  function new(string name = "spi_base_seq");
    super.new(name);
  endfunction

  virtual task pre_start();
    uvm_phase phase = get_starting_phase();
    if (phase != null)
      phase.raise_objection(this);
  endtask

  virtual task post_start();
    uvm_phase phase = get_starting_phase();
    if (phase != null)
      phase.drop_objection(this);
  endtask

endclass : spi_base_seq

class spi_wr_csr_seq extends spi_base_seq;

  `uvm_object_utils(spi_wr_csr_seq)

  rand logic [7:0]      reg_addr;
  rand logic [31:0]     wdata;
  rand spi_lane_mode_t  lane_mode;

  constraint reg_addr_c { reg_addr < 8'h40; }

  function new(string name = "spi_wr_csr_seq");
    super.new(name);
  endfunction

  virtual task body();
    spi_drv_item item;
    item = spi_drv_item::type_id::create("item");
    start_item(item);
    if (!item.randomize() with {
      opcode       == SPI_WR_CSR;
      reg_addr     == local::reg_addr;
      wdata.size() == 1;
      wdata[0]     == local::wdata;
      lane_mode    == local::lane_mode;
    }) `uvm_error(get_type_name(), "Randomization failed")
    finish_item(item);
  endtask

endclass : spi_wr_csr_seq

class spi_rd_csr_seq extends spi_base_seq;

  `uvm_object_utils(spi_rd_csr_seq)

  rand logic [7:0]      reg_addr;
  rand spi_lane_mode_t  lane_mode;

  constraint reg_addr_c { reg_addr < 8'h40; }

  function new(string name = "spi_rd_csr_seq");
    super.new(name);
  endfunction

  virtual task body();
    spi_drv_item item;
    item = spi_drv_item::type_id::create("item");
    start_item(item);
    if (!item.randomize() with {
      opcode    == SPI_RD_CSR;
      reg_addr  == local::reg_addr;
      lane_mode == local::lane_mode;
    }) `uvm_error(get_type_name(), "Randomization failed")
    finish_item(item);
  endtask

endclass : spi_rd_csr_seq

class spi_ahb_wr32_seq extends spi_base_seq;

  `uvm_object_utils(spi_ahb_wr32_seq)

  rand logic [31:0]     addr;
  rand logic [31:0]     wdata;
  rand spi_lane_mode_t  lane_mode;

  constraint addr_c { addr[1:0] == 2'b00; }

  function new(string name = "spi_ahb_wr32_seq");
    super.new(name);
  endfunction

  virtual task body();
    spi_drv_item item;
    item = spi_drv_item::type_id::create("item");
    start_item(item);
    if (!item.randomize() with {
      opcode       == SPI_AHB_WR32;
      addr         == local::addr;
      wdata.size() == 1;
      wdata[0]     == local::wdata;
      lane_mode    == local::lane_mode;
    }) `uvm_error(get_type_name(), "Randomization failed")
    finish_item(item);
  endtask

endclass : spi_ahb_wr32_seq

class spi_ahb_rd32_seq extends spi_base_seq;

  `uvm_object_utils(spi_ahb_rd32_seq)

  rand logic [31:0]     addr;
  rand spi_lane_mode_t  lane_mode;

  constraint addr_c { addr[1:0] == 2'b00; }

  function new(string name = "spi_ahb_rd32_seq");
    super.new(name);
  endfunction

  virtual task body();
    spi_drv_item item;
    item = spi_drv_item::type_id::create("item");
    start_item(item);
    if (!item.randomize() with {
      opcode    == SPI_AHB_RD32;
      addr      == local::addr;
      lane_mode == local::lane_mode;
    }) `uvm_error(get_type_name(), "Randomization failed")
    finish_item(item);
  endtask

endclass : spi_ahb_rd32_seq

class spi_ahb_wr_burst_seq extends spi_base_seq;

  `uvm_object_utils(spi_ahb_wr_burst_seq)

  rand logic [31:0]     addr;
  rand logic [4:0]      burst_len;
  rand logic [31:0]     wdata[];
  rand spi_lane_mode_t  lane_mode;

  constraint burst_len_c { burst_len inside {1, 4, 8, 16}; }
  constraint addr_c      { addr[1:0] == 2'b00; }
  constraint wdata_size  { wdata.size() == burst_len; }

  function new(string name = "spi_ahb_wr_burst_seq");
    super.new(name);
  endfunction

  virtual task body();
    spi_drv_item item;
    item = spi_drv_item::type_id::create("item");
    start_item(item);
    if (!item.randomize() with {
      opcode       == SPI_AHB_WR_BURST;
      addr         == local::addr;
      burst_len    == local::burst_len;
      wdata.size() == local::burst_len;
      foreach (wdata[i]) wdata[i] == local::wdata[i];
      lane_mode    == local::lane_mode;
    }) `uvm_error(get_type_name(), "Randomization failed")
    finish_item(item);
  endtask

endclass : spi_ahb_wr_burst_seq

class spi_ahb_rd_burst_seq extends spi_base_seq;

  `uvm_object_utils(spi_ahb_rd_burst_seq)

  rand logic [31:0]     addr;
  rand logic [4:0]      burst_len;
  rand spi_lane_mode_t  lane_mode;

  constraint burst_len_c { burst_len inside {1, 4, 8, 16}; }
  constraint addr_c      { addr[1:0] == 2'b00; }

  function new(string name = "spi_ahb_rd_burst_seq");
    super.new(name);
  endfunction

  virtual task body();
    spi_drv_item item;
    item = spi_drv_item::type_id::create("item");
    start_item(item);
    if (!item.randomize() with {
      opcode    == SPI_AHB_RD_BURST;
      addr      == local::addr;
      burst_len == local::burst_len;
      lane_mode == local::lane_mode;
    }) `uvm_error(get_type_name(), "Randomization failed")
    finish_item(item);
  endtask

endclass : spi_ahb_rd_burst_seq

class spi_random_seq extends spi_base_seq;

  `uvm_object_utils(spi_random_seq)

  rand int unsigned num_transactions;

  constraint num_trans_c { soft num_transactions inside {[5:20]}; }

  function new(string name = "spi_random_seq");
    super.new(name);
  endfunction

  virtual task body();
    for (int i = 0; i < num_transactions; i++) begin
      spi_drv_item item;
      item = spi_drv_item::type_id::create("item");
      start_item(item);
      if (!item.randomize())
        `uvm_error(get_type_name(), "Randomization failed")
      finish_item(item);
    end
  endtask

endclass : spi_random_seq

class spi_frame_abort_seq extends spi_base_seq;

  `uvm_object_utils(spi_frame_abort_seq)

  rand spi_opcode_t     opcode;
  rand logic [31:0]     addr;
  rand logic [4:0]      burst_len;
  rand spi_lane_mode_t  lane_mode;
  rand int unsigned     abort_after_bits;

  constraint burst_len_c { burst_len inside {1, 4, 8, 16}; }
  constraint addr_c      { addr[1:0] == 2'b00; }
  constraint abort_c     { abort_after_bits inside {[4:40]}; }

  function new(string name = "spi_frame_abort_seq");
    super.new(name);
  endfunction

  virtual task body();
    spi_drv_item item;
    item = spi_drv_item::type_id::create("item");
    start_item(item);
    if (!item.randomize() with {
      opcode          == local::opcode;
      addr            == local::addr;
      burst_len       == local::burst_len;
      lane_mode       == local::lane_mode;
      frame_abort     == 1;
      abort_after_bits == local::abort_after_bits;
    }) `uvm_error(get_type_name(), "Randomization failed")
    finish_item(item);
  endtask

endclass : spi_frame_abort_seq

`endif // SPI_SEQ_LIB_SV
