`ifndef SPI_TRANSACTION_SV
`define SPI_TRANSACTION_SV

class spi_transaction extends uvm_sequence_item;

    // AI gen: Command fields per DV_SPEC Agent 1 transaction definition
    rand bit [7:0]  opcode;
    rand bit [4:0]  burst_len;
    rand bit [2:0]  hburst;
    rand bit [7:0]  reg_addr;
    rand bit [31:0] addr;
    rand bit [31:0] wdata[];
    rand bit [1:0]  lane_mode;

    // AI gen: Response fields
    rand bit [7:0]  status;
    rand bit [31:0] rdata[];

    // AI gen: Protocol flags
    rand bit        frame_abort;
    rand bit        is_write;
    rand bit        is_burst;
    rand bit        is_csr;

    // AI gen: Control/config
    rand bit        en;
    rand bit        test_mode;

    `uvm_object_utils_begin(spi_transaction)
        `uvm_field_int(opcode,    UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(burst_len, UVM_ALL_ON | UVM_DEC)
        `uvm_field_int(hburst,    UVM_ALL_ON | UVM_BIN)
        `uvm_field_int(reg_addr,  UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(addr,      UVM_ALL_ON | UVM_HEX)
        `uvm_field_array_int(wdata, UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(lane_mode, UVM_ALL_ON | UVM_BIN)
        `uvm_field_int(status,    UVM_ALL_ON | UVM_HEX)
        `uvm_field_array_int(rdata, UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(frame_abort, UVM_ALL_ON)
        `uvm_field_int(is_write,  UVM_ALL_ON)
        `uvm_field_int(is_burst,  UVM_ALL_ON)
        `uvm_field_int(is_csr,    UVM_ALL_ON)
        `uvm_field_int(en,        UVM_ALL_ON)
        `uvm_field_int(test_mode, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "spi_transaction");
        super.new(name);
        en        = 1'b1;
        test_mode = 1'b1;
        frame_abort = 1'b0;
    endfunction

    // AI gen: Constraint - derive fields from opcode
    function void post_randomize();
        case (opcode)
            `OPC_WR_CSR: begin
                is_write = 1'b1; is_burst = 1'b0; is_csr = 1'b1;
                hburst = `HBURST_SINGLE;
            end
            `OPC_RD_CSR: begin
                is_write = 1'b0; is_burst = 1'b0; is_csr = 1'b1;
                hburst = `HBURST_SINGLE;
            end
            `OPC_AHB_WR32: begin
                is_write = 1'b1; is_burst = 1'b0; is_csr = 1'b0;
                burst_len = 5'd1; hburst = `HBURST_SINGLE;
            end
            `OPC_AHB_RD32: begin
                is_write = 1'b0; is_burst = 1'b0; is_csr = 1'b0;
                burst_len = 5'd1; hburst = `HBURST_SINGLE;
            end
            `OPC_AHB_WR_BURST: begin
                is_write = 1'b1; is_burst = 1'b1; is_csr = 1'b0;
            end
            `OPC_AHB_RD_BURST: begin
                is_write = 1'b0; is_burst = 1'b1; is_csr = 1'b0;
            end
            default: begin
                is_write = 1'b0; is_burst = 1'b0; is_csr = 1'b0;
                hburst = `HBURST_SINGLE;
            end
        endcase
        // AI gen: Map burst_len to hburst
        if (is_burst) begin
            case (burst_len)
                5'd1:  hburst = `HBURST_SINGLE;
                5'd4:  hburst = `HBURST_INCR4;
                5'd8:  hburst = `HBURST_INCR8;
                5'd16: hburst = `HBURST_INCR16;
                default: hburst = 3'b000;
            endcase
        end
    endfunction

    // AI gen: Calculate frame length in bits
    function int get_frame_bits();
        case (opcode)
            `OPC_WR_CSR:       return `WR_CSR_FRAME_BITS;
            `OPC_RD_CSR:       return `RD_CSR_FRAME_BITS;
            `OPC_AHB_WR32:     return `AHB_WR32_FRAME_BITS;
            `OPC_AHB_RD32:     return `AHB_RD32_FRAME_BITS;
            `OPC_AHB_WR_BURST: return `BURST_HEADER_BITS + 32 * burst_len;
            `OPC_AHB_RD_BURST: return `BURST_HEADER_BITS;
            default:           return 8;
        endcase
    endfunction

    // AI gen: Calculate response length in bits
    function int get_response_bits();
        case (opcode)
            `OPC_WR_CSR,
            `OPC_AHB_WR32,
            `OPC_AHB_WR_BURST: return 8;
            `OPC_RD_CSR,
            `OPC_AHB_RD32:     return 40;
            `OPC_AHB_RD_BURST: return 8 + 32 * burst_len;
            default:           return 8;
        endcase
    endfunction

    // AI gen: Get bits per clock based on lane_mode
    function int get_bpc();
        case (lane_mode)
            `LANE_MODE_1BIT:  return 1;
            `LANE_MODE_4BIT:  return 4;
            `LANE_MODE_8BIT:  return 8;
            `LANE_MODE_16BIT: return 16;
            default:          return 16;
        endcase
    endfunction

    // AI gen: Calculate RX beat count
    function int calc_rx_beats();
        int frame_bits = get_frame_bits();
        int bpc = get_bpc();
        return (frame_bits + bpc - 1) / bpc;
    endfunction

    // AI gen: Calculate TX beat count
    function int calc_tx_beats();
        int resp_bits = get_response_bits();
        int bpc = get_bpc();
        return (resp_bits + bpc - 1) / bpc;
    endfunction

    // AI gen: Convert2string for debug
    virtual function string convert2string();
        string s;
        s = $sformatf("opcode=0x%02h burst_len=%0d hburst=0b%03b reg_addr=0x%02h addr=0x%08h lane_mode=%0d",
                       opcode, burst_len, hburst, reg_addr, addr, lane_mode);
        if (wdata.size() > 0) begin
            s = {s, $sformatf(" wdata[%0d]=", wdata.size())};
            foreach (wdata[i]) s = {s, $sformatf("0x%08h ", wdata[i])};
        end
        s = {s, $sformatf(" status=0x%02h", status)};
        if (rdata.size() > 0) begin
            s = {s, $sformatf(" rdata[%0d]=", rdata.size())};
            foreach (rdata[i]) s = {s, $sformatf("0x%08h ", rdata[i])};
        end
        if (frame_abort) s = {s, " FRAME_ABORT"};
        return s;
    endfunction

endclass : spi_transaction

`endif
