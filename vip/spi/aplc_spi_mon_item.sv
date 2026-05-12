`ifndef APLC_SPI_MON_ITEM_SV
`define APLC_SPI_MON_ITEM_SV

class aplc_spi_mon_item extends aplc_spi_item;

    `uvm_object_utils(aplc_spi_mon_item)

    bit        has_frame_abort;
    bit        has_lane_changed;
    bit        has_ta_err;
    time       start_time;
    time       end_time;

    function new(string name = "aplc_spi_mon_item");
        super.new(name);
    endfunction

    virtual function string convert2string();
        string s;
        s = super.convert2string();
        s = {s, $sformatf(" [%0t..%0t]", start_time, end_time)};
        if (has_frame_abort)  s = {s, " FRAME_ABORT"};
        if (has_lane_changed) s = {s, " LANE_CHANGED"};
        if (has_ta_err)       s = {s, " TA_ERR"};
        return s;
    endfunction

    virtual function void do_copy(uvm_object rhs);
        aplc_spi_mon_item other;
        super.do_copy(rhs);
        if (!$cast(other, rhs)) return;
        has_frame_abort  = other.has_frame_abort;
        has_lane_changed = other.has_lane_changed;
        has_ta_err       = other.has_ta_err;
        start_time       = other.start_time;
        end_time         = other.end_time;
    endfunction

endclass

`endif
