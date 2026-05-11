/******************************************************************************
 * SPI VIP Transaction Item
 * Description: Transaction item for SPI VIP
 ******************************************************************************/

`ifndef SPI_ITEM_SV
`define SPI_ITEM_SV

class spi_item extends uvm_sequence_item;

    `uvm_object_utils(spi_item)

    rand spi_opcode_t opcode;
    rand spi_addr_t addr;
    rand spi_data_t data;
    rand bit [4:0] burst_len;
    rand spi_lane_mode_t lane_mode;
    rand spi_direction_t direction;

    rand bit [31:0] wdata_queue[$];
    bit [31:0] rdata_queue[$];

    spi_status_t status;
    bit has_response;
    int trans_delay;

    time start_time;
    time end_time;

    rand int unsigned inter_byte_delay;

    constraint burst_len_valid {
        burst_len inside {1, 4, 8, 16};
    }

    constraint opcode_addr_align {
        if(opcode inside {CMD_AHB_WR32, CMD_AHB_RD32, CMD_AHB_WR_BURST, CMD_AHB_RD_BURST}) {
            addr[1:0] == 2'b00;
        }
    }

    constraint inter_byte_delay_range {
        inter_byte_delay inside {0, 1, 2, 5, 10};
    }

    function new(string name = "spi_item");
        super.new(name);
        has_response = 0;
        trans_delay = 0;
    endfunction

    virtual function string convert2string();
        string s;
        s = $sformatf("opcode: %s(0x%02h), addr: 0x%08h, lane: %s, dir: %s",
            opcode_to_string(opcode), opcode, addr, lane_mode_to_string(lane_mode),
            direction == DIR_WRITE ? "WRITE" : "READ");

        if(opcode inside {CMD_WR_CSR, CMD_AHB_WR32, CMD_AHB_WR_BURST}) begin
            s = {s, $sformatf(", wdata: 0x%08h", data)};
        end

        if(opcode inside {CMD_AHB_WR_BURST, CMD_AHB_RD_BURST}) begin
            s = {s, $sformatf(", burst_len: %0d", burst_len)};
        end

        if(has_response) begin
            s = {s, $sformatf(", status: %s(0x%02h)", status_to_string(status), status)};
            if(opcode inside {CMD_RD_CSR, CMD_AHB_RD32, CMD_AHB_RD_BURST}) begin
                s = {s, $sformatf(", rdata: 0x%08h", data)};
            end
        end

        return s;
    endfunction

    virtual function void do_copy(uvm_object rhs);
        spi_item rhs_item;
        super.do_copy(rhs);
        if(!$cast(rhs_item, rhs)) return;
        opcode = rhs_item.opcode;
        addr = rhs_item.addr;
        data = rhs_item.data;
        burst_len = rhs_item.burst_len;
        lane_mode = rhs_item.lane_mode;
        direction = rhs_item.direction;
        status = rhs_item.status;
        has_response = rhs_item.has_response;
        trans_delay = rhs_item.trans_delay;
    endfunction

    virtual function bit do_compare(uvm_object rhs, uvm_comparer comparer);
        spi_item rhs_item;
        if(!$cast(rhs_item, rhs)) return 0;
        return (opcode == rhs_item.opcode) &&
               (addr == rhs_item.addr) &&
               (data == rhs_item.data) &&
               (burst_len == rhs_item.burst_len) &&
               (lane_mode == rhs_item.lane_mode);
    endfunction

    virtual function int get_frame_length();
        case(opcode)
            CMD_WR_CSR: return 48;
            CMD_RD_CSR: return 16;
            CMD_AHB_WR32: return 72;
            CMD_AHB_RD32: return 40;
            CMD_AHB_WR_BURST: return 48 + 32 * burst_len;
            CMD_AHB_RD_BURST: return 48;
            default: return 0;
        endcase
    endfunction

    virtual function int get_response_length();
        case(opcode)
            CMD_WR_CSR, CMD_AHB_WR32: return 8;
            CMD_RD_CSR, CMD_AHB_RD32: return 40;
            CMD_AHB_WR_BURST: return 8;
            CMD_AHB_RD_BURST: return 8 + 32 * burst_len;
            default: return 8;
        endcase
    endfunction

endclass

`endif
