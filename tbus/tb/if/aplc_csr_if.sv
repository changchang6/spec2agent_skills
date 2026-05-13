// APLC CSR Interface - simulates external CSR File
`ifndef APLC_CSR_IF_SV
`define APLC_CSR_IF_SV

interface aplc_csr_if (
    input  logic        clk,
    input  logic        rst_n
);

    logic        csr_rd_en;
    logic        csr_wr_en;
    logic [7:0]  csr_addr;
    logic [31:0] csr_wdata;
    logic [31:0] csr_rdata;

    // CSR register storage
    logic [31:0] csr_regs [0:63];

    // Clocking block for slave (responds to DUT)
    clocking slv_cb @(posedge clk);
        input  csr_rd_en, csr_wr_en, csr_addr, csr_wdata;
        output csr_rdata;
    endclocking

    // Clocking block for monitor
    clocking mon_cb @(posedge clk);
        input csr_rd_en, csr_wr_en, csr_addr, csr_wdata, csr_rdata;
    endclocking

    // Initialize CSR registers
    initial begin
        csr_rdata = 32'b0;
        foreach (csr_regs[i]) csr_regs[i] = 32'b0;
        // VERSION register
        csr_regs[8'h00 >> 2] = 32'h0000_0220; // v2.2
    end

    // Respond to CSR read/write
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            csr_rdata <= 32'b0;
        end else begin
            if (csr_wr_en) begin
                case (csr_addr)
                    8'h04: csr_regs[8'h04 >> 2] <= csr_wdata;
                    8'h10: begin
                        if (csr_wdata[0]) // WC: write 1 clear
                            csr_regs[8'h10 >> 2] <= 32'b0;
                    end
                    default: ; // RO registers - ignore write
                endcase
            end
            if (csr_rd_en) begin
                csr_rdata <= csr_regs[csr_addr >> 2];
            end
        end
    end

endinterface

`endif
