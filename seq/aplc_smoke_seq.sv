// APLC Smoke Sequence
// Basic write-read verification: WR_CSR -> RD_CSR, AHB_WR32 -> AHB_RD32

`ifndef APLC_SMOKE_SEQ_SV
`define APLC_SMOKE_SEQ_SV

import aplc_spi_pkg::*;

class aplc_smoke_seq extends aplc_spi_base_seq;

    `uvm_object_utils(aplc_smoke_seq)

    function new(string name = "aplc_smoke_seq");
        super.new(name);
    endfunction

    virtual task body();
        logic [31:0] rdata;
        logic [7:0]  status;
        bit          pass;

        pass = 1;

        // ---- Test 1: WR_CSR / RD_CSR to ext CSR (0x20) ----
        // Address 0x20 is outside DUT internal CSR range (0x00-0x10),
        // so it is handled by the external CSR file model in TB
        `uvm_info("APLC_SMOKE", "=== Test 1: WR_CSR / RD_CSR ===", UVM_LOW)
        send_wr_csr(8'h20, 32'hCAFE_BABE, APLC_LANE_16BIT);
        #100ns;
        send_rd_csr(8'h20, APLC_LANE_16BIT, rdata, status);
        if (status !== 8'h00) begin
            `uvm_error("APLC_SMOKE", $sformatf("RD_CSR status=0x%02h (expected 0x00)", status))
            pass = 0;
        end else if (rdata !== 32'hCAFE_BABE) begin
            `uvm_error("APLC_SMOKE", $sformatf("RD_CSR data mismatch: got 0x%08h expected 0xCAFE_BABE", rdata))
            pass = 0;
        end else begin
            `uvm_info("APLC_SMOKE", $sformatf("RD_CSR addr=0x20 data=0x%08h OK", rdata), UVM_LOW)
        end

        // ---- Test 2: AHB_WR32 / AHB_RD32 ----
        `uvm_info("APLC_SMOKE", "=== Test 2: AHB_WR32 / AHB_RD32 ===", UVM_LOW)
        send_ahb_wr32(32'h0001_0000, 32'hDEAD_BEEF, APLC_LANE_16BIT, status);
        if (status !== 8'h00) begin
            `uvm_error("APLC_SMOKE", $sformatf("AHB_WR32 status=0x%02h (expected 0x00)", status))
            pass = 0;
        end
        #100ns;
        send_ahb_rd32(32'h0001_0000, APLC_LANE_16BIT, rdata, status);
        if (status !== 8'h00) begin
            `uvm_error("APLC_SMOKE", $sformatf("AHB_RD32 status=0x%02h (expected 0x00)", status))
            pass = 0;
        end else if (rdata !== 32'hDEAD_BEEF) begin
            `uvm_error("APLC_SMOKE", $sformatf("AHB_RD32 data mismatch: got 0x%08h expected 0xDEAD_BEEF", rdata))
            pass = 0;
        end else begin
            `uvm_info("APLC_SMOKE", $sformatf("AHB_RD32 addr=0x%08h data=0x%08h OK", 32'h0001_0000, rdata), UVM_LOW)
        end

        // ---- Test 3: AHB_RD_BURST x4 ----
        `uvm_info("APLC_SMOKE", "=== Test 3: AHB_RD_BURST x4 ===", UVM_LOW)
        begin
            logic [31:0] rdata_q[$];
            send_ahb_rd_burst(32'h0001_0000, 5'd4, APLC_LANE_16BIT, rdata_q, status);
            if (status !== 8'h00) begin
                `uvm_error("APLC_SMOKE", $sformatf("AHB_RD_BURST status=0x%02h (expected 0x00)", status))
                pass = 0;
            end else begin
                `uvm_info("APLC_SMOKE", $sformatf("AHB_RD_BURST x4 got %0d beats, status OK", rdata_q.size()), UVM_LOW)
            end
        end

        // ---- Summary ----
        if (pass) begin
            `uvm_info("APLC_SMOKE", "=== SMOKE TEST PASSED ===", UVM_LOW)
        end else begin
            `uvm_error("APLC_SMOKE", "=== SMOKE TEST FAILED ===")
        end
    endtask

endclass

`endif
