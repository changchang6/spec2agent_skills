// APLC CSR File Model
// Register file model responding to CSR read/write from DUT
// Same-cycle combinational read (matching DUT's SLC_CSRFILE behavior)

`ifndef APLC_CSR_FILE_SV
`define APLC_CSR_FILE_SV

import uvm_pkg::*;
`include "uvm_macros.svh"

class aplc_csr_file extends uvm_component;

    `uvm_component_utils(aplc_csr_file)

    virtual aplc_csr_if m_vif;

    logic [31:0] regs [0:63];

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual aplc_csr_if)::get(this, "", "csr_vif", m_vif)) begin
            `uvm_fatal("APLC_CSR_FILE", "Cannot get csr_vif")
        end
        foreach (regs[i]) regs[i] = 32'h0;
    endfunction

    virtual task run_phase(uvm_phase phase);
        fork
            csr_handler();
        join
    endtask

    virtual task csr_handler();
        forever begin
            @(posedge m_vif.clk);
            if (m_vif.rst_n !== 1'b1) begin
                m_vif.csr_rdata <= 32'h0;
                continue;
            end

            // Handle CSR write (same cycle)
            if (m_vif.csr_wr_en === 1'b1) begin
                if (m_vif.csr_addr < 8'h40) begin
                    regs[m_vif.csr_addr] = m_vif.csr_wdata;
                    `uvm_info("APLC_CSR_FILE", $sformatf("CSR WR addr=0x%02h data=0x%08h", m_vif.csr_addr, m_vif.csr_wdata), UVM_HIGH)
                end
            end

            // Handle CSR read (same-cycle combinational, matching DUT's SLC_CSRFILE)
            if (m_vif.csr_rd_en === 1'b1) begin
                if (m_vif.csr_addr < 8'h40) begin
                    m_vif.csr_rdata <= regs[m_vif.csr_addr];
                    `uvm_info("APLC_CSR_FILE", $sformatf("CSR RD addr=0x%02h data=0x%08h", m_vif.csr_addr, regs[m_vif.csr_addr]), UVM_HIGH)
                end else begin
                    m_vif.csr_rdata <= 32'h0;
                end
            end else begin
                m_vif.csr_rdata <= 32'h0;
            end
        end
    endtask

    virtual function logic [31:0] read_reg(logic [7:0] addr);
        if (addr < 8'h40)
            return regs[addr];
        else
            return 32'h0;
    endfunction

    virtual function void write_reg(logic [7:0] addr, logic [31:0] data);
        if (addr < 8'h40)
            regs[addr] = data;
    endfunction

endclass

`endif
