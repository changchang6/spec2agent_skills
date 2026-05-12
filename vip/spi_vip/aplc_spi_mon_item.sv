// APLC SPI VIP Monitor Item
// Extended item with timing and protocol information for monitor output

`ifndef APLC_SPI_MON_ITEM_SV
`define APLC_SPI_MON_ITEM_SV

class aplc_spi_mon_item extends aplc_spi_item;

    `uvm_object_utils(aplc_spi_mon_item)

    typedef enum {
        PHASE_REQUEST,
        PHASE_TURNAROUND,
        PHASE_RESPONSE
    } aplc_phase_e;

    // Timing information
    time         req_start_time;
    time         req_end_time;
    time         resp_start_time;
    time         resp_end_time;
    int unsigned rx_cycles;
    int unsigned tx_cycles;

    // Protocol check flags
    bit          lane_mode_stable;
    bit          turnaround_ok;
    bit          frame_complete;

    // Error flags
    bit          has_frame_abort;
    bit          has_protocol_error;

    // Observed lane mode during transaction
    aplc_lane_mode_e observed_lane_mode;

    function new(string name = "aplc_spi_mon_item");
        super.new(name);
    endfunction

    virtual function void do_copy(uvm_object rhs);
        aplc_spi_mon_item other;
        super.do_copy(rhs);
        $cast(other, rhs);
        req_start_time    = other.req_start_time;
        req_end_time      = other.req_end_time;
        resp_start_time   = other.resp_start_time;
        resp_end_time     = other.resp_end_time;
        rx_cycles         = other.rx_cycles;
        tx_cycles         = other.tx_cycles;
        lane_mode_stable  = other.lane_mode_stable;
        turnaround_ok     = other.turnaround_ok;
        frame_complete    = other.frame_complete;
        has_frame_abort   = other.has_frame_abort;
        has_protocol_error = other.has_protocol_error;
        observed_lane_mode = other.observed_lane_mode;
    endfunction

    virtual function string convert2string();
        string s = super.convert2string();
        s = {s, $sformatf(" rx_cyc=%0d tx_cyc=%0d lane_stable=%0b ta_ok=%0b frame_abort=%0b",
                           rx_cycles, tx_cycles, lane_mode_stable, turnaround_ok, has_frame_abort)};
        return s;
    endfunction

endclass

`endif
