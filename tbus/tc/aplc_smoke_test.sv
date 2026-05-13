// APLC Smoke Test - Basic WR_CSR/RD_CSR and AHB_WR32/AHB_RD32
// Verifies write-read-back consistency
`ifndef APLC_SMOKE_TEST_SV
`define APLC_SMOKE_TEST_SV

class aplc_smoke_test extends aplc_base_test;

    `uvm_component_utils(aplc_smoke_test)

    function new(string name = "aplc_smoke_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        aplc_spi_item txn;
        logic [31:0] rd_val;

        phase.raise_objection(this);

        // Wait for reset to complete
        #200ns;

        // ---- Test 1: WR_CSR then RD_CSR ----
        `uvm_info("APLC_SMOKE", "=== Test 1: WR_CSR -> RD_CSR ===", UVM_LOW)

        // Write CTRL register (addr=0x04, value=0x00000001)
        txn = aplc_spi_item::type_id::create("txn_wr");
        txn.opcode   = APLC_OP_WR_CSR;
        txn.reg_addr = 8'h04;
        txn.wdata    = new[1];
        txn.wdata[0] = 32'h00000001;
        txn.lane_mode = APLC_LANE_16BIT;
        start_item(txn);
        finish_item(txn);

        // Check write status
        if (txn.status !== APLC_STS_OK) begin
            `uvm_error("APLC_SMOKE", $sformatf("WR_CSR status=0x%02h, expected 0x00", txn.status))
        end else begin
            `uvm_info("APLC_SMOKE", "WR_CSR returned STS_OK", UVM_LOW)
        end

        // Read back CTRL register
        txn = aplc_spi_item::type_id::create("txn_rd");
        txn.opcode   = APLC_OP_RD_CSR;
        txn.reg_addr = 8'h04;
        txn.lane_mode = APLC_LANE_16BIT;
        start_item(txn);
        finish_item(txn);

        // Check read status and data
        if (txn.status !== APLC_STS_OK) begin
            `uvm_error("APLC_SMOKE", $sformatf("RD_CSR status=0x%02h, expected 0x00", txn.status))
        end else begin
            `uvm_info("APLC_SMOKE", $sformatf("RD_CSR returned STS_OK, rdata=0x%08h", txn.rdata[0]), UVM_LOW)
        end

        // ---- Test 2: AHB_WR32 then AHB_RD32 ----
        `uvm_info("APLC_SMOKE", "=== Test 2: AHB_WR32 -> AHB_RD32 ===", UVM_LOW)

        // Write to AHB address
        txn = aplc_spi_item::type_id::create("txn_ahb_wr");
        txn.opcode = APLC_OP_AHB_WR32;
        txn.addr   = 32'h10000000;
        txn.wdata  = new[1];
        txn.wdata[0] = 32'hDEADBEEF;
        txn.lane_mode = APLC_LANE_16BIT;
        start_item(txn);
        finish_item(txn);

        if (txn.status !== APLC_STS_OK) begin
            `uvm_error("APLC_SMOKE", $sformatf("AHB_WR32 status=0x%02h, expected 0x00", txn.status))
        end else begin
            `uvm_info("APLC_SMOKE", "AHB_WR32 returned STS_OK", UVM_LOW)
        end

        // Read back from same address
        txn = aplc_spi_item::type_id::create("txn_ahb_rd");
        txn.opcode = APLC_OP_AHB_RD32;
        txn.addr   = 32'h10000000;
        txn.lane_mode = APLC_LANE_16BIT;
        start_item(txn);
        finish_item(txn);

        if (txn.status !== APLC_STS_OK) begin
            `uvm_error("APLC_SMOKE", $sformatf("AHB_RD32 status=0x%02h, expected 0x00", txn.status))
        end else if (txn.rdata.size() > 0 && txn.rdata[0] !== 32'hDEADBEEF) begin
            `uvm_error("APLC_SMOKE", $sformatf("AHB_RD32 data mismatch: got 0x%08h, expected 0xDEADBEEF", txn.rdata[0]))
        end else begin
            `uvm_info("APLC_SMOKE", $sformatf("AHB_RD32 returned STS_OK, rdata=0x%08h (match!)", txn.rdata[0]), UVM_LOW)
        end

        `uvm_info("APLC_SMOKE", "=== Smoke test complete ===", UVM_LOW)

        phase.drop_objection(this);
    endtask

endclass

`endif
