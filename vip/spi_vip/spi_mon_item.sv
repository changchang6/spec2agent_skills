`ifndef SPI_MON_ITEM_SV
`define SPI_MON_ITEM_SV

class spi_mon_item extends spi_item;

  `uvm_object_utils(spi_mon_item)

  spi_direction_t direction;
  time            start_time;
  time            end_time;

  // Observed control signals
  logic        en_obs;
  logic        test_mode_obs;
  logic [1:0]  lane_mode_obs;

  // Observed FIFO status
  logic rxfifo_empty_obs;
  logic rxfifo_full_obs;
  logic txfifo_empty_obs;
  logic txfifo_full_obs;

  // Frame abort detected
  bit frame_aborted;

  function new(string name = "spi_mon_item");
    super.new(name);
  endfunction

  virtual function void do_copy(uvm_object rhs);
    spi_mon_item rhs_;
    super.do_copy(rhs);
    if (!$cast(rhs_, rhs)) return;
    direction        = rhs_.direction;
    start_time       = rhs_.start_time;
    end_time         = rhs_.end_time;
    en_obs           = rhs_.en_obs;
    test_mode_obs    = rhs_.test_mode_obs;
    lane_mode_obs    = rhs_.lane_mode_obs;
    rxfifo_empty_obs = rhs_.rxfifo_empty_obs;
    rxfifo_full_obs  = rhs_.rxfifo_full_obs;
    txfifo_empty_obs = rhs_.txfifo_empty_obs;
    txfifo_full_obs  = rhs_.txfifo_full_obs;
    frame_aborted    = rhs_.frame_aborted;
  endfunction

  virtual function string convert2string();
    string s = super.convert2string();
    s = {s, $sformatf(" dir=%s start=%0t end=%0t", direction.name(), start_time, end_time)};
    if (frame_aborted)
      s = {s, " ABORTED"};
    return s;
  endfunction

endclass : spi_mon_item

`endif // SPI_MON_ITEM_SV
