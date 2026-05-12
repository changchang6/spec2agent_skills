`ifndef APLC_SPI_MON_ITEM_SV
`define APLC_SPI_MON_ITEM_SV

class aplc_spi_mon_item extends uvm_sequence_item;
    `uvm_object_utils(aplc_spi_mon_item)

    aplc_opcode_e     opcode;
    logic [7:0]       reg_addr;
    logic [31:0]      addr;
    logic [4:0]       burst_len;
    aplc_lane_mode_e  lane_mode;

    logic [7:0]       status;
    logic [31:0]      rdata_q[$];
    logic [31:0]      wdata_q[$];

    logic             frame_abort;
    logic             is_response;
    string            flags;

    function new(string name = "aplc_spi_mon_item");
        super.new(name);
        flags = "";
    endfunction

    virtual function string convert2string();
        string s;
        if (is_response) begin
            s = $sformatf("[RSP] opcode=%0s status=0x%02h lane=%0s",
                           opcode.name(), status, lane_mode.name());
            if (rdata_q.size() > 0) begin
                foreach (rdata_q[i])
                    s = {s, $sformatf(" rdata[%0d]=0x%08h", i, rdata_q[i])};
            end
        end else begin
            s = $sformatf("[REQ] opcode=%0s reg_addr=0x%02h addr=0x%08h burst_len=%0d lane=%0s",
                           opcode.name(), reg_addr, addr, burst_len, lane_mode.name());
            if (wdata_q.size() > 0) begin
                foreach (wdata_q[i])
                    s = {s, $sformatf(" wdata[%0d]=0x%08h", i, wdata_q[i])};
            end
        end
        if (frame_abort) s = {s, " FRAME_ABORT"};
        if (flags != "") s = {s, " ", flags};
        return s;
    endfunction

    virtual function void do_print(uvm_printer printer);
        printer.m_string = convert2string();
    endfunction

endclass

`endif
