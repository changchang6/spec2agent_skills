`ifndef SPI_DRV_ITEM_SV
`define SPI_DRV_ITEM_SV

class spi_drv_item extends spi_item;

  `uvm_object_utils(spi_drv_item)

  rand int unsigned trans_delay;
  rand bit          frame_abort;
  rand int unsigned abort_after_bits;

  constraint trans_delay_default {
    soft trans_delay inside {[0:10]};
  }

  constraint frame_abort_default {
    soft frame_abort == 0;
  }

  constraint abort_after_bits_valid {
    if (frame_abort)
      abort_after_bits inside {[1:560]};
    else
      abort_after_bits == 0;
  }

  function new(string name = "spi_drv_item");
    super.new(name);
  endfunction

  virtual function void do_copy(uvm_object rhs);
    spi_drv_item rhs_;
    super.do_copy(rhs);
    if (!$cast(rhs_, rhs)) return;
    trans_delay      = rhs_.trans_delay;
    frame_abort      = rhs_.frame_abort;
    abort_after_bits = rhs_.abort_after_bits;
  endfunction

  virtual function string convert2string();
    string s = super.convert2string();
    s = {s, $sformatf(" delay=%0d abort=%0b after=%0d",
                       trans_delay, frame_abort, abort_after_bits)};
    return s;
  endfunction

endclass : spi_drv_item

`endif // SPI_DRV_ITEM_SV
