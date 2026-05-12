// APLC SPI VIP Sequence Library
// Provides sequences for all RTM testcase requirements

`ifndef APLC_SPI_SEQ_LIB_SV
`define APLC_SPI_SEQ_LIB_SV

// Base sequence with common utilities
class aplc_spi_base_seq extends uvm_sequence #(aplc_spi_item);

    `uvm_object_utils(aplc_spi_base_seq)
    `uvm_declare_p_sequencer(aplc_spi_sequencer)

    aplc_spi_agent_config m_cfg;

    function new(string name = "aplc_spi_base_seq");
        super.new(name);
    endfunction

    virtual task pre_start();
        super.pre_start();
        if (p_sequencer != null && p_sequencer.m_cfg != null) begin
            m_cfg = p_sequencer.m_cfg;
        end
    endtask

    virtual task send_item(aplc_spi_item item);
        start_item(item);
        finish_item(item);
    endtask

    virtual task send_wr_csr(logic [7:0] reg_addr, logic [31:0] wdata, aplc_lane_mode_e lane = APLC_LANE_16BIT);
        aplc_spi_item item;
        item = aplc_spi_item::type_id::create("item");
        item.opcode    = APLC_OPCODE_WR_CSR;
        item.reg_addr  = reg_addr;
        item.wdata     = wdata;
        item.lane_mode = lane;
        item.en        = 1'b1;
        item.test_mode = 1'b1;
        item.burst_len = 5'd0;
        send_item(item);
    endtask

    virtual task send_rd_csr(logic [7:0] reg_addr, aplc_lane_mode_e lane,
                             output logic [31:0] rdata, output logic [7:0] status);
        aplc_spi_item item;
        item = aplc_spi_item::type_id::create("item");
        item.opcode    = APLC_OPCODE_RD_CSR;
        item.reg_addr  = reg_addr;
        item.lane_mode = lane;
        item.en        = 1'b1;
        item.test_mode = 1'b1;
        item.burst_len = 5'd0;
        send_item(item);
        rdata  = item.rdata;
        status = item.status;
    endtask

    virtual task send_ahb_wr32(logic [31:0] addr, logic [31:0] wdata, aplc_lane_mode_e lane,
                               output logic [7:0] status);
        aplc_spi_item item;
        item = aplc_spi_item::type_id::create("item");
        item.opcode    = APLC_OPCODE_AHB_WR32;
        item.addr      = addr;
        item.wdata     = wdata;
        item.lane_mode = lane;
        item.en        = 1'b1;
        item.test_mode = 1'b1;
        item.burst_len = 5'd0;
        send_item(item);
        status = item.status;
    endtask

    virtual task send_ahb_rd32(logic [31:0] addr, aplc_lane_mode_e lane,
                               output logic [31:0] rdata, output logic [7:0] status);
        aplc_spi_item item;
        item = aplc_spi_item::type_id::create("item");
        item.opcode    = APLC_OPCODE_AHB_RD32;
        item.addr      = addr;
        item.lane_mode = lane;
        item.en        = 1'b1;
        item.test_mode = 1'b1;
        item.burst_len = 5'd0;
        send_item(item);
        rdata  = item.rdata;
        status = item.status;
    endtask

    virtual task send_ahb_wr_burst(logic [31:0] addr, logic [4:0] burst_len, aplc_lane_mode_e lane,
                                   ref logic [31:0] wdata_q[$], output logic [7:0] status);
        aplc_spi_item item;
        item = aplc_spi_item::type_id::create("item");
        item.opcode      = APLC_OPCODE_AHB_WR_BURST;
        item.addr        = addr;
        item.burst_len   = burst_len;
        item.wdata_burst = wdata_q;
        item.lane_mode   = lane;
        item.en          = 1'b1;
        item.test_mode   = 1'b1;
        send_item(item);
        status = item.status;
    endtask

    virtual task send_ahb_rd_burst(logic [31:0] addr, logic [4:0] burst_len, aplc_lane_mode_e lane,
                                   output logic [31:0] rdata_q[$], output logic [7:0] status);
        aplc_spi_item item;
        item = aplc_spi_item::type_id::create("item");
        item.opcode    = APLC_OPCODE_AHB_RD_BURST;
        item.addr      = addr;
        item.burst_len = burst_len;
        item.lane_mode = lane;
        item.en        = 1'b1;
        item.test_mode = 1'b1;
        send_item(item);
        rdata_q = item.rdata_burst;
        status  = item.status;
    endtask

endclass


// WR_CSR sequence
class aplc_spi_wr_csr_seq extends aplc_spi_base_seq;

    `uvm_object_utils(aplc_spi_wr_csr_seq)

    rand logic [7:0]  reg_addr;
    rand logic [31:0] wdata;
    rand aplc_lane_mode_e lane_mode;

    constraint c_reg_addr { reg_addr < 8'h40; }

    function new(string name = "aplc_spi_wr_csr_seq");
        super.new(name);
    endfunction

    virtual task body();
        aplc_spi_item item;
        item = aplc_spi_item::type_id::create("item");
        item.opcode    = APLC_OPCODE_WR_CSR;
        item.reg_addr  = reg_addr;
        item.wdata     = wdata;
        item.lane_mode = lane_mode;
        item.en        = 1'b1;
        item.test_mode = 1'b1;
        item.burst_len = 5'd0;
        send_item(item);
    endtask

endclass


// RD_CSR sequence
class aplc_spi_rd_csr_seq extends aplc_spi_base_seq;

    `uvm_object_utils(aplc_spi_rd_csr_seq)

    rand logic [7:0]  reg_addr;
    rand aplc_lane_mode_e lane_mode;

    constraint c_reg_addr { reg_addr < 8'h40; }

    function new(string name = "aplc_spi_rd_csr_seq");
        super.new(name);
    endfunction

    virtual task body();
        aplc_spi_item item;
        item = aplc_spi_item::type_id::create("item");
        item.opcode    = APLC_OPCODE_RD_CSR;
        item.reg_addr  = reg_addr;
        item.lane_mode = lane_mode;
        item.en        = 1'b1;
        item.test_mode = 1'b1;
        item.burst_len = 5'd0;
        send_item(item);
    endtask

endclass


// AHB write 32 sequence
class aplc_spi_ahb_wr32_seq extends aplc_spi_base_seq;

    `uvm_object_utils(aplc_spi_ahb_wr32_seq)

    rand logic [31:0] addr;
    rand logic [31:0] wdata;
    rand aplc_lane_mode_e lane_mode;

    constraint c_addr_aligned { addr[1:0] == 2'b00; }

    function new(string name = "aplc_spi_ahb_wr32_seq");
        super.new(name);
    endfunction

    virtual task body();
        aplc_spi_item item;
        item = aplc_spi_item::type_id::create("item");
        item.opcode    = APLC_OPCODE_AHB_WR32;
        item.addr      = addr;
        item.wdata     = wdata;
        item.lane_mode = lane_mode;
        item.en        = 1'b1;
        item.test_mode = 1'b1;
        item.burst_len = 5'd0;
        send_item(item);
    endtask

endclass


// AHB read 32 sequence
class aplc_spi_ahb_rd32_seq extends aplc_spi_base_seq;

    `uvm_object_utils(aplc_spi_ahb_rd32_seq)

    rand logic [31:0] addr;
    rand aplc_lane_mode_e lane_mode;

    constraint c_addr_aligned { addr[1:0] == 2'b00; }

    function new(string name = "aplc_spi_ahb_rd32_seq");
        super.new(name);
    endfunction

    virtual task body();
        aplc_spi_item item;
        item = aplc_spi_item::type_id::create("item");
        item.opcode    = APLC_OPCODE_AHB_RD32;
        item.addr      = addr;
        item.lane_mode = lane_mode;
        item.en        = 1'b1;
        item.test_mode = 1'b1;
        item.burst_len = 5'd0;
        send_item(item);
    endtask

endclass


// AHB write burst sequence
class aplc_spi_ahb_wr_burst_seq extends aplc_spi_base_seq;

    `uvm_object_utils(aplc_spi_ahb_wr_burst_seq)

    rand logic [31:0] addr;
    rand logic [4:0]  burst_len;
    rand aplc_lane_mode_e lane_mode;

    constraint c_burst_len { burst_len inside {5'd4, 5'd8, 5'd16}; }
    constraint c_addr_aligned { addr[1:0] == 2'b00; }

    function new(string name = "aplc_spi_ahb_wr_burst_seq");
        super.new(name);
    endfunction

    virtual task body();
        aplc_spi_item item;
        item = aplc_spi_item::type_id::create("item");
        item.opcode    = APLC_OPCODE_AHB_WR_BURST;
        item.addr      = addr;
        item.burst_len = burst_len;
        item.lane_mode = lane_mode;
        item.en        = 1'b1;
        item.test_mode = 1'b1;
        `uvm_rand_send(item)
    endtask

endclass


// AHB read burst sequence
class aplc_spi_ahb_rd_burst_seq extends aplc_spi_base_seq;

    `uvm_object_utils(aplc_spi_ahb_rd_burst_seq)

    rand logic [31:0] addr;
    rand logic [4:0]  burst_len;
    rand aplc_lane_mode_e lane_mode;

    constraint c_burst_len { burst_len inside {5'd4, 5'd8, 5'd16}; }
    constraint c_addr_aligned { addr[1:0] == 2'b00; }

    function new(string name = "aplc_spi_ahb_rd_burst_seq");
        super.new(name);
    endfunction

    virtual task body();
        aplc_spi_item item;
        item = aplc_spi_item::type_id::create("item");
        item.opcode    = APLC_OPCODE_AHB_RD_BURST;
        item.addr      = addr;
        item.burst_len = burst_len;
        item.lane_mode = lane_mode;
        item.en        = 1'b1;
        item.test_mode = 1'b1;
        `uvm_rand_send(item)
    endtask

endclass


// Error injection: bad opcode sequence
class aplc_spi_bad_opcode_seq extends aplc_spi_base_seq;

    `uvm_object_utils(aplc_spi_bad_opcode_seq)

    rand logic [7:0] bad_opcode;
    rand aplc_lane_mode_e lane_mode;

    constraint c_bad_opcode {
        !(bad_opcode inside {8'h10, 8'h11, 8'h20, 8'h21, 8'h22, 8'h23});
    }

    function new(string name = "aplc_spi_bad_opcode_seq");
        super.new(name);
    endfunction

    virtual task body();
        aplc_spi_item item;
        item = aplc_spi_item::type_id::create("item");
        item.opcode    = aplc_opcode_e'(bad_opcode);
        item.lane_mode = lane_mode;
        item.en        = 1'b1;
        item.test_mode = 1'b1;
        item.burst_len = 5'd0;
        send_item(item);
    endtask

endclass


// Error injection: disabled module sequence
class aplc_spi_disabled_seq extends aplc_spi_base_seq;

    `uvm_object_utils(aplc_spi_disabled_seq)

    rand aplc_opcode_e opcode;
    rand aplc_lane_mode_e lane_mode;

    function new(string name = "aplc_spi_disabled_seq");
        super.new(name);
    endfunction

    virtual task body();
        aplc_spi_item item;
        item = aplc_spi_item::type_id::create("item");
        item.opcode    = opcode;
        item.lane_mode = lane_mode;
        item.en        = 1'b0;
        item.test_mode = 1'b1;
        item.burst_len = 5'd0;
        send_item(item);
    endtask

endclass


// Error injection: not in test mode sequence
class aplc_spi_not_in_test_seq extends aplc_spi_base_seq;

    `uvm_object_utils(aplc_spi_not_in_test_seq)

    rand aplc_opcode_e opcode;
    rand aplc_lane_mode_e lane_mode;

    function new(string name = "aplc_spi_not_in_test_seq");
        super.new(name);
    endfunction

    virtual task body();
        aplc_spi_item item;
        item = aplc_spi_item::type_id::create("item");
        item.opcode    = opcode;
        item.lane_mode = lane_mode;
        item.en        = 1'b1;
        item.test_mode = 1'b0;
        item.burst_len = 5'd0;
        send_item(item);
    endtask

endclass


// Error injection: bad CSR address sequence
class aplc_spi_bad_reg_seq extends aplc_spi_base_seq;

    `uvm_object_utils(aplc_spi_bad_reg_seq)

    rand logic [7:0] bad_reg_addr;
    rand aplc_lane_mode_e lane_mode;

    constraint c_bad_reg { bad_reg_addr >= 8'h40; }

    function new(string name = "aplc_spi_bad_reg_seq");
        super.new(name);
    endfunction

    virtual task body();
        aplc_spi_item item;
        item = aplc_spi_item::type_id::create("item");
        item.opcode    = APLC_OPCODE_WR_CSR;
        item.reg_addr  = bad_reg_addr;
        item.lane_mode = lane_mode;
        item.en        = 1'b1;
        item.test_mode = 1'b1;
        item.burst_len = 5'd0;
        send_item(item);
    endtask

endclass


// Error injection: alignment error sequence
class aplc_spi_align_err_seq extends aplc_spi_base_seq;

    `uvm_object_utils(aplc_spi_align_err_seq)

    rand logic [31:0] misaligned_addr;
    rand aplc_lane_mode_e lane_mode;

    constraint c_misaligned { misaligned_addr[1:0] != 2'b00; }

    function new(string name = "aplc_spi_align_err_seq");
        super.new(name);
    endfunction

    virtual task body();
        aplc_spi_item item;
        item = aplc_spi_item::type_id::create("item");
        item.opcode    = APLC_OPCODE_AHB_WR32;
        item.addr      = misaligned_addr;
        item.lane_mode = lane_mode;
        item.en        = 1'b1;
        item.test_mode = 1'b1;
        item.burst_len = 5'd0;
        send_item(item);
    endtask

endclass


// Error injection: bad burst length sequence
class aplc_spi_bad_burst_seq extends aplc_spi_base_seq;

    `uvm_object_utils(aplc_spi_bad_burst_seq)

    rand logic [4:0] bad_burst_len;
    rand logic [31:0] addr;
    rand aplc_lane_mode_e lane_mode;

    constraint c_bad_burst { !(bad_burst_len inside {5'd1, 5'd4, 5'd8, 5'd16}); }
    constraint c_addr_aligned { addr[1:0] == 2'b00; }

    function new(string name = "aplc_spi_bad_burst_seq");
        super.new(name);
    endfunction

    virtual task body();
        aplc_spi_item item;
        item = aplc_spi_item::type_id::create("item");
        item.opcode    = APLC_OPCODE_AHB_RD_BURST;
        item.addr      = addr;
        item.burst_len = bad_burst_len;
        item.lane_mode = lane_mode;
        item.en        = 1'b1;
        item.test_mode = 1'b1;
        send_item(item);
    endtask

endclass


// Error injection: burst 1KB boundary crossing sequence
class aplc_spi_burst_bound_seq extends aplc_spi_base_seq;

    `uvm_object_utils(aplc_spi_burst_bound_seq)

    rand logic [4:0] burst_len;
    rand logic [31:0] addr;
    rand aplc_lane_mode_e lane_mode;

    constraint c_burst_len { burst_len inside {5'd4, 5'd8, 5'd16}; }
    constraint c_addr_aligned { addr[1:0] == 2'b00; }
    constraint c_cross_1kb { (addr[9:0] + 4*(burst_len - 1)) >= 10'h400; }

    function new(string name = "aplc_spi_burst_bound_seq");
        super.new(name);
    endfunction

    virtual task body();
        aplc_spi_item item;
        item = aplc_spi_item::type_id::create("item");
        item.opcode    = APLC_OPCODE_AHB_RD_BURST;
        item.addr      = addr;
        item.burst_len = burst_len;
        item.lane_mode = lane_mode;
        item.en        = 1'b1;
        item.test_mode = 1'b1;
        send_item(item);
    endtask

endclass


// Random multi-command sequence (TC_036)
class aplc_spi_rand_multi_cmd_seq extends aplc_spi_base_seq;

    `uvm_object_utils(aplc_spi_rand_multi_cmd_seq)

    rand int unsigned num_commands;
    rand aplc_lane_mode_e lane_mode;

    constraint c_num_commands { num_commands inside {[5:20]}; }

    function new(string name = "aplc_spi_rand_multi_cmd_seq");
        super.new(name);
    endfunction

    virtual task body();
        for (int i = 0; i < num_commands; i++) begin
            aplc_spi_item item;
            item = aplc_spi_item::type_id::create($sformatf("item_%0d", i));
            item.lane_mode = lane_mode;
            item.en        = 1'b1;
            item.test_mode = 1'b1;
            `uvm_rand_send(item)
        end
    endtask

endclass


// Full cross coverage sequence (TC_053)
class aplc_spi_full_cross_seq extends aplc_spi_base_seq;

    `uvm_object_utils(aplc_spi_full_cross_seq)

    function new(string name = "aplc_spi_full_cross_seq");
        super.new(name);
    endfunction

    virtual task body();
        aplc_opcode_e opcodes[] = '{APLC_OPCODE_WR_CSR, APLC_OPCODE_RD_CSR,
                                     APLC_OPCODE_AHB_WR32, APLC_OPCODE_AHB_RD32,
                                     APLC_OPCODE_AHB_WR_BURST, APLC_OPCODE_AHB_RD_BURST};
        aplc_lane_mode_e lanes[] = '{APLC_LANE_1BIT, APLC_LANE_4BIT, APLC_LANE_8BIT, APLC_LANE_16BIT};
        logic [4:0] burst_lens[] = '{5'd1, 5'd4, 5'd8, 5'd16};

        foreach (lanes[l]) begin
            foreach (opcodes[o]) begin
                aplc_spi_item item;
                item = aplc_spi_item::type_id::create("item");
                item.opcode    = opcodes[o];
                item.lane_mode = lanes[l];
                item.en        = 1'b1;
                item.test_mode = 1'b1;

                if (opcodes[o] inside {APLC_OPCODE_AHB_WR_BURST, APLC_OPCODE_AHB_RD_BURST}) begin
                    foreach (burst_lens[b]) begin
                        item.burst_len = burst_lens[b];
                        `uvm_send(item)
                    end
                end else begin
                    item.burst_len = 5'd0;
                    `uvm_send(item)
                end
            end
        end
    endtask

endclass


// Write-read-back verification sequence (CSR and AHB)
class aplc_spi_wr_rd_back_seq extends aplc_spi_base_seq;

    `uvm_object_utils(aplc_spi_wr_rd_back_seq)

    rand int unsigned num_iterations;
    rand aplc_lane_mode_e lane_mode;

    constraint c_iterations { num_iterations inside {[3:10]}; }

    function new(string name = "aplc_spi_wr_rd_back_seq");
        super.new(name);
    endfunction

    virtual task body();
        logic [31:0] rdata;
        logic [7:0]  status;

        for (int i = 0; i < num_iterations; i++) begin
            logic [7:0]  csr_addr;
            logic [31:0] csr_wdata;
            logic [31:0] ahb_addr;
            logic [31:0] ahb_wdata;

            // CSR write-read-back
            csr_addr  = $urandom_range(8'h00, 8'h10);
            csr_wdata = $urandom_range(32'h0, 32'hFFFF_FFFF);
            // Skip CTRL SOFT_RST bit (bit4) to avoid accidental reset
            if (csr_addr == 8'h04) csr_wdata[4] = 1'b0;

            send_wr_csr(csr_addr, csr_wdata, lane_mode);
            send_rd_csr(csr_addr, lane_mode, rdata, status);
            if (status !== 8'h00) begin
                `uvm_error("APLC_WR_RD", $sformatf("CSR RD status=0x%02h addr=0x%02h", status, csr_addr))
            end else if (rdata !== csr_wdata) begin
                `uvm_error("APLC_WR_RD", $sformatf("CSR data mismatch: addr=0x%02h exp=0x%08h got=0x%08h", csr_addr, csr_wdata, rdata))
            end

            // AHB write-read-back
            ahb_addr  = {$urandom_range(0, 65535) << 2};
            ahb_wdata = $urandom_range(32'h0, 32'hFFFF_FFFF);
            send_ahb_wr32(ahb_addr, ahb_wdata, lane_mode, status);
            if (status !== 8'h00) begin
                `uvm_warning("APLC_WR_RD", $sformatf("AHB WR status=0x%02h addr=0x%08h (slave may not respond)", status, ahb_addr))
            end else begin
                send_ahb_rd32(ahb_addr, lane_mode, rdata, status);
                if (status === 8'h00 && rdata !== ahb_wdata) begin
                    `uvm_error("APLC_WR_RD", $sformatf("AHB data mismatch: addr=0x%08h exp=0x%08h got=0x%08h", ahb_addr, ahb_wdata, rdata))
                end
            end
        end
    endtask

endclass


`endif
