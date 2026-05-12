`ifndef APLC_SMOKE_SEQ_SV
`define APLC_SMOKE_SEQ_SV

class aplc_smoke_seq extends uvm_sequence #(aplc_spi_item);

    `uvm_object_utils(aplc_smoke_seq)
    `uvm_declare_p_sequencer(aplc_spi_sequencer)

    function new(string name = "aplc_smoke_seq");
        super.new(name);
    endfunction

    virtual task body();
        aplc_spi_item item;

        // Step 1: WR_CSR - write CTRL register (addr=0x04) with EN=1
        `uvm_info(get_type_name(), "Step 1: WR_CSR CTRL.EN=1", UVM_LOW)
        item = aplc_spi_item::type_id::create("item");
        start_item(item);
        item.opcode    = APLC_SPI_WR_CSR;
        item.reg_addr  = 8'h04;
        item.wdata     = new[1];
        item.wdata[0]  = 32'h00000001;
        item.lane_mode = 2'b11;
        finish_item(item);
        if (item.status != APLC_SPI_STS_OK) begin
            `uvm_error(get_type_name(), $sformatf("WR_CSR failed: status=0x%02h", item.status))
        end

        // Step 2: RD_CSR - read back CTRL register
        `uvm_info(get_type_name(), "Step 2: RD_CSR CTRL", UVM_LOW)
        item = aplc_spi_item::type_id::create("item");
        start_item(item);
        item.opcode    = APLC_SPI_RD_CSR;
        item.reg_addr  = 8'h04;
        item.lane_mode = 2'b11;
        finish_item(item);
        if (item.status != APLC_SPI_STS_OK) begin
            `uvm_error(get_type_name(), $sformatf("RD_CSR failed: status=0x%02h", item.status))
        end else if (item.rdata.size() > 0) begin
            `uvm_info(get_type_name(), $sformatf("RD_CSR CTRL = 0x%08h", item.rdata[0]), UVM_LOW)
        end

        // Step 3: AHB_WR32 - write to AHB address
        `uvm_info(get_type_name(), "Step 3: AHB_WR32 addr=0x10000000 data=0xDEADBEEF", UVM_LOW)
        item = aplc_spi_item::type_id::create("item");
        start_item(item);
        item.opcode    = APLC_SPI_AHB_WR32;
        item.addr      = 32'h10000000;
        item.wdata     = new[1];
        item.wdata[0]  = 32'hDEADBEEF;
        item.lane_mode = 2'b11;
        finish_item(item);
        if (item.status != APLC_SPI_STS_OK) begin
            `uvm_error(get_type_name(), $sformatf("AHB_WR32 failed: status=0x%02h", item.status))
        end

        // Step 4: AHB_RD32 - read back AHB address
        `uvm_info(get_type_name(), "Step 4: AHB_RD32 addr=0x10000000", UVM_LOW)
        item = aplc_spi_item::type_id::create("item");
        start_item(item);
        item.opcode    = APLC_SPI_AHB_RD32;
        item.addr      = 32'h10000000;
        item.lane_mode = 2'b11;
        finish_item(item);
        if (item.status != APLC_SPI_STS_OK) begin
            `uvm_error(get_type_name(), $sformatf("AHB_RD32 failed: status=0x%02h", item.status))
        end else if (item.rdata.size() > 0) begin
            `uvm_info(get_type_name(), $sformatf("AHB_RD32 data = 0x%08h", item.rdata[0]), UVM_LOW)
            if (item.rdata[0] !== 32'hDEADBEEF) begin
                `uvm_error(get_type_name(),
                    $sformatf("Data mismatch: expected 0xDEADBEEF, got 0x%08h", item.rdata[0]))
            end else begin
                `uvm_info(get_type_name(), "Smoke test PASSED: write-read data matches", UVM_LOW)
            end
        end

    endtask

endclass

`endif
