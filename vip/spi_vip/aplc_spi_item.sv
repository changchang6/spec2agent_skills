// APLC SPI VIP Sequence Item
// Represents a single APLC SPI command transaction

`ifndef APLC_SPI_ITEM_SV
`define APLC_SPI_ITEM_SV

class aplc_spi_item extends uvm_sequence_item;

    `uvm_object_utils(aplc_spi_item)

    // ---- Request fields ----
    rand aplc_opcode_e   opcode;
    rand logic [7:0]     reg_addr;
    rand logic [31:0]    addr;
    rand logic [31:0]    wdata;
    rand logic [31:0]    wdata_burst[$];
    rand logic [4:0]     burst_len;

    // ---- Configuration fields ----
    rand aplc_lane_mode_e lane_mode;
    rand bit              en;
    rand bit              test_mode;

    // ---- Response fields (filled by driver/monitor) ----
    logic [7:0]           status;
    logic [31:0]          rdata;
    logic [31:0]          rdata_burst[$];

    // ---- Timing control ----
    rand int unsigned     pre_command_delay;
    rand int unsigned     post_command_delay;

    constraint c_opcode_valid {
        opcode inside {APLC_OPCODE_WR_CSR, APLC_OPCODE_RD_CSR,
                       APLC_OPCODE_AHB_WR32, APLC_OPCODE_AHB_RD32,
                       APLC_OPCODE_AHB_WR_BURST, APLC_OPCODE_AHB_RD_BURST};
    }

    constraint c_burst_len_valid {
        if (opcode inside {APLC_OPCODE_AHB_WR_BURST, APLC_OPCODE_AHB_RD_BURST})
            burst_len inside {5'd4, 5'd8, 5'd16};
        else
            burst_len == 5'd0;
    }

    constraint c_addr_aligned {
        if (opcode inside {APLC_OPCODE_AHB_WR32, APLC_OPCODE_AHB_RD32,
                           APLC_OPCODE_AHB_WR_BURST, APLC_OPCODE_AHB_RD_BURST})
            addr[1:0] == 2'b00;
    }

    constraint c_csr_addr_valid {
        if (opcode inside {APLC_OPCODE_WR_CSR, APLC_OPCODE_RD_CSR})
            reg_addr < 8'h40;
    }

    constraint c_burst_wdata_size {
        if (opcode == APLC_OPCODE_AHB_WR_BURST)
            wdata_burst.size() == burst_len;
        else
            wdata_burst.size() == 0;
    }

    constraint c_en_testmode {
        en == 1'b1;
        test_mode == 1'b1;
    }

    constraint c_delays {
        pre_command_delay  inside {[0:5]};
        post_command_delay inside {[0:5]};
    }

    constraint c_default_lane {
        lane_mode == APLC_LANE_16BIT;
    }

    function new(string name = "aplc_spi_item");
        super.new(name);
    endfunction

    function void post_randomize();
        if (opcode == APLC_OPCODE_AHB_WR_BURST && wdata_burst.size() != burst_len) begin
            wdata_burst.delete();
            for (int i = 0; i < burst_len; i++) begin
                wdata_burst.push_back($urandom_range(32'hFFFF_FFFF));
            end
        end
    endfunction

    virtual function void do_copy(uvm_object rhs);
        aplc_spi_item other;
        super.do_copy(rhs);
        $cast(other, rhs);
        opcode        = other.opcode;
        reg_addr      = other.reg_addr;
        addr          = other.addr;
        wdata         = other.wdata;
        wdata_burst   = other.wdata_burst;
        burst_len     = other.burst_len;
        lane_mode     = other.lane_mode;
        en            = other.en;
        test_mode     = other.test_mode;
        status        = other.status;
        rdata         = other.rdata;
        rdata_burst   = other.rdata_burst;
        pre_command_delay  = other.pre_command_delay;
        post_command_delay = other.post_command_delay;
    endfunction

    virtual function bit do_compare(uvm_object rhs, uvm_comparer comparer);
        aplc_spi_item other;
        $cast(other, rhs);
        do_compare = (opcode == other.opcode) &&
                     (reg_addr == other.reg_addr) &&
                     (addr == other.addr) &&
                     (wdata == other.wdata) &&
                     (burst_len == other.burst_len) &&
                     (status == other.status);
    endfunction

    virtual function string convert2string();
        string s;
        s = $sformatf("opcode=%s reg_addr=0x%02h addr=0x%08h wdata=0x%08h burst_len=%0d lane=%0d en=%0b test_mode=%0b status=0x%02h",
                       opcode.name(), reg_addr, addr, wdata, burst_len, lane_mode, en, test_mode, status);
        if (opcode inside {APLC_OPCODE_AHB_WR_BURST, APLC_OPCODE_AHB_RD_BURST}) begin
            s = {s, $sformatf(" rdata_burst.size=%0d wdata_burst.size=%0d", rdata_burst.size(), wdata_burst.size())};
        end
        return s;
    endfunction

    virtual function void do_print(uvm_printer printer);
        printer.print_string("item", convert2string());
    endfunction

    virtual function void do_record(uvm_recorder recorder);
        super.do_record(recorder);
    endfunction

endclass

`endif
