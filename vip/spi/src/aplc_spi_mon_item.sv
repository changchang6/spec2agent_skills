// APLC SPI monitor transaction item
`ifndef APLC_SPI_MON_ITEM_SV
`define APLC_SPI_MON_ITEM_SV

class aplc_spi_mon_item extends uvm_sequence_item;

    // Request fields (observed on pdi)
    rand aplc_opcode_e   opcode;
    rand logic [7:0]     reg_addr;
    rand logic [31:0]    addr;
    rand logic [31:0]    wdata[];    // write data beats
    rand logic [4:0]     burst_len;

    // Response fields (observed on pdo)
    rand logic [7:0]     status;
    rand logic [31:0]    rdata[];    // read data beats

    // Lane mode observed during transaction
    rand aplc_lane_mode_e lane_mode;

    // Protocol anomaly flags
    rand bit             frame_abort;
    rand bit             lane_changed;
    rand bit             ta_err;

    // Direction: request or response
    typedef enum {
        MON_REQ,
        MON_RSP
    } mon_dir_e;
    rand mon_dir_e       direction;

    `uvm_object_utils(aplc_spi_mon_item)

    function new(string name = "aplc_spi_mon_item");
        super.new(name);
        frame_abort  = 1'b0;
        lane_changed = 1'b0;
        ta_err       = 1'b0;
    endfunction

    virtual function string convert2string();
        string s;
        s = $sformatf("[%s] opcode=%s lane=%0d", direction.name(), opcode.name(), lane_mode);
        if (opcode inside {APLC_OP_WR_CSR, APLC_OP_RD_CSR})
            s = {s, $sformatf(" reg_addr=0x%02h", reg_addr)};
        if (opcode inside {APLC_OP_AHB_WR32, APLC_OP_AHB_RD32,
                          APLC_OP_AHB_WR_BURST, APLC_OP_AHB_RD_BURST})
            s = {s, $sformatf(" addr=0x%08h", addr)};
        if (opcode inside {APLC_OP_AHB_WR_BURST, APLC_OP_AHB_RD_BURST})
            s = {s, $sformatf(" burst_len=%0d", burst_len)};
        if (wdata.size() > 0)
            s = {s, $sformatf(" wdata[0]=0x%08h", wdata[0])};
        s = {s, $sformatf(" status=0x%02h", status)};
        if (rdata.size() > 0)
            s = {s, $sformatf(" rdata[0]=0x%08h", rdata[0])};
        if (frame_abort)  s = {s, " FRAME_ABORT"};
        if (lane_changed) s = {s, " LANE_CHANGED"};
        if (ta_err)       s = {s, " TA_ERR"};
        return s;
    endfunction

endclass

`endif
