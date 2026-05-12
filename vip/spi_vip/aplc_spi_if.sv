// APLC SPI VIP Interface
// Contains SVA assertions for protocol checking based on RTM Checker List

`ifndef APLC_SPI_IF_SV
`define APLC_SPI_IF_SV

import uvm_pkg::*;

interface aplc_spi_if (
    input  logic        clk,
    input  logic        rst_n
);

    logic        en;
    logic        test_mode;
    logic        pcs_n;
    logic [15:0] pdi;
    logic [15:0] pdo;
    logic        pdo_oe;
    logic [1:0]  lane_mode;
    logic        rxfifo_empty;
    logic        rxfifo_full;
    logic        txfifo_empty;
    logic        txfifo_full;

    // Check enable switches (parameters for generate eligibility)
    parameter bit EN_PROTOCOL_CHECKS = 1;
    parameter bit EN_RESET_CHECKS    = 1;
    parameter bit EN_X_Z_CHECKS      = 1;

    // Internal tracking for assertions
    logic pcs_n_d;
    logic pdo_oe_d;
    logic [1:0] lane_mode_d;
    logic prev_pdo_oe;

    always_ff @(posedge clk) begin
        pcs_n_d      <= pcs_n;
        pdo_oe_d     <= pdo_oe;
        lane_mode_d  <= lane_mode;
        prev_pdo_oe  <= pdo_oe;
    end

    // ------------------------------------------------
    // Clocking blocks
    // ------------------------------------------------
    clocking drv_cb @(posedge clk);
        default input #1step output #1step;
        output en, test_mode, pcs_n, pdi, lane_mode;
        input  pdo, pdo_oe;
        input  rxfifo_empty, rxfifo_full, txfifo_empty, txfifo_full;
    endclocking

    clocking mon_cb @(posedge clk);
        default input #1step output #1step;
        input en, test_mode, pcs_n, pdi, pdo, pdo_oe, lane_mode;
        input rxfifo_empty, rxfifo_full, txfifo_empty, txfifo_full;
    endclocking

    // ------------------------------------------------
    // Modports
    // ------------------------------------------------
    modport drv_mp (
        clocking drv_cb,
        input rst_n
    );

    modport mon_mp (
        clocking mon_cb,
        input rst_n
    );

    // ------------------------------------------------
    // SVA: Reset State Checker (CHK_001)
    // ------------------------------------------------
    generate if (EN_RESET_CHECKS) begin : gEN_RESET_CHECKS
        APLC_RST_PDO_OE: assert property (
            @(posedge clk) !$isunknown(rst_n) |=> (rst_n === 1'b0) |-> (pdo_oe === 1'b0)
        ) else `uvm_error("APLC_SPI_RST", "pdo_oe not 0 after reset");

        APLC_RST_RXFIFO_EMPTY: assert property (
            @(posedge clk) !$isunknown(rst_n) |=> (rst_n === 1'b0) |-> (rxfifo_empty === 1'b1)
        ) else `uvm_error("APLC_SPI_RST", "rxfifo not empty after reset");

        APLC_RST_TXFIFO_EMPTY: assert property (
            @(posedge clk) !$isunknown(rst_n) |=> (rst_n === 1'b0) |-> (txfifo_empty === 1'b1)
        ) else `uvm_error("APLC_SPI_RST", "txfifo not empty after reset");

        APLC_RST_COVER: cover property (
            @(posedge clk) $fell(rst_n)
        );
    end endgenerate

    // ------------------------------------------------
    // SVA: X/Z Checks
    // ------------------------------------------------
    generate if (EN_X_Z_CHECKS) begin : gEN_X_Z_CHECKS
        APLC_PCS_N_NOT_XZ: assert property (
            @(posedge clk) disable iff (rst_n !== 1'b1)
            !$isunknown(pcs_n)
        ) else `uvm_error("APLC_SPI_XZ", "pcs_n is X or Z");

        APLC_PDO_OE_NOT_XZ: assert property (
            @(posedge clk) disable iff (rst_n !== 1'b1)
            !$isunknown(pdo_oe)
        ) else `uvm_error("APLC_SPI_XZ", "pdo_oe is X or Z");

        APLC_LANE_MODE_NOT_XZ: assert property (
            @(posedge clk) disable iff (rst_n !== 1'b1)
            !$isunknown(lane_mode)
        ) else `uvm_error("APLC_SPI_XZ", "lane_mode is X or Z");

        APLC_FIFO_STATUS_NOT_XZ: assert property (
            @(posedge clk) disable iff (rst_n !== 1'b1)
            !$isunknown(rxfifo_empty) &&
            !$isunknown(rxfifo_full)  &&
            !$isunknown(txfifo_empty) &&
            !$isunknown(txfifo_full)
        ) else `uvm_error("APLC_SPI_XZ", "FIFO status signal is X or Z");
    end endgenerate

    // ------------------------------------------------
    // SVA: Lane Mode Stability (CHK_005)
    // lane_mode must remain stable during pcs_n=0
    // ------------------------------------------------
    generate if (EN_PROTOCOL_CHECKS) begin : gen_lane_stability
        APLC_LANE_STABLE_DURING_TX: assert property (
            @(posedge clk) disable iff (!$isunknown(rst_n) && rst_n === 1'b0)
            (pcs_n === 1'b0) |=> $stable(lane_mode)
        ) else `uvm_error("APLC_SPI_LANE", "lane_mode changed during active transaction (pcs_n=0)");

        APLC_LANE_STABLE_COVER: cover property (
            @(posedge clk) disable iff (!$isunknown(rst_n) && rst_n === 1'b0)
            $fell(pcs_n) ##1 (pcs_n === 1'b0) [*1:50] ##1 $rose(pcs_n)
        );
    end endgenerate

    // ------------------------------------------------
    // SVA: Frame Protocol Checker (CHK_006)
    // ------------------------------------------------
    generate if (EN_PROTOCOL_CHECKS) begin : gen_frame_protocol
        // pcs_n should be 1 (idle) when no transaction active
        APLC_PCS_N_IDLE_HIGH: assert property (
            @(posedge clk) disable iff (!$isunknown(rst_n) && rst_n === 1'b0)
            (pcs_n === 1'b0 && pdo_oe === 1'b0 && !$fell(pcs_n)) |-> !$isunknown(pdi)
        ) else `uvm_error("APLC_SPI_FRAME", "pdi unknown during active request phase");

        // pdo_oe should be 0 when pcs_n is 1 (idle)
        APLC_PDO_OE_IDLE: assert property (
            @(posedge clk) disable iff (!$isunknown(rst_n) && rst_n === 1'b0)
            (pcs_n === 1'b1) |-> (pdo_oe === 1'b0)
        ) else `uvm_error("APLC_SPI_FRAME", "pdo_oe asserted while pcs_n high (idle)");

        // pdo_oe transitions: can only go high after pcs_n was low (transaction in progress)
        APLC_PDO_OE_RISE_DURING_TX: assert property (
            @(posedge clk) disable iff (!$isunknown(rst_n) && rst_n === 1'b0)
            $rose(pdo_oe) |-> !$isunknown(pcs_n) && (pcs_n === 1'b0)
        ) else `uvm_error("APLC_SPI_FRAME", "pdo_oe rose while pcs_n not low");

        // Cover: pcs_n falling to rising (complete transaction)
        APLC_TRANSACTION_COVER: cover property (
            @(posedge clk) disable iff (!$isunknown(rst_n) && rst_n === 1'b0)
            $fell(pcs_n) ##1 $rose(pcs_n)
        );

        // Cover: pdo_oe high during response
        APLC_PDO_OE_RESPONSE_COVER: cover property (
            @(posedge clk) disable iff (!$isunknown(rst_n) && rst_n === 1'b0)
            $rose(pdo_oe)
        );
    end endgenerate

    // ------------------------------------------------
    // SVA: Turnaround check (CHK_006)
    // After request phase, 1-cycle turnaround before response
    // ------------------------------------------------
    generate if (EN_PROTOCOL_CHECKS) begin : gen_turnaround
        // Monitor that pdo_oe doesn't rise too quickly (need at least 1 turnaround cycle)
        APLC_TURNAROUND_EXISTS: assert property (
            @(posedge clk) disable iff (!$isunknown(rst_n) && rst_n === 1'b0)
            $rose(pdo_oe) |-> !$fell(pdo_oe) throughout (pdo_oe === 1'b1) [*1]
        ) else `uvm_error("APLC_SPI_TA", "pdo_oe glitch detected");
    end endgenerate

    // ------------------------------------------------
    // SVA: FIFO status mutual exclusion (CHK_011)
    // empty and full cannot both be 1
    // ------------------------------------------------
    generate if (EN_PROTOCOL_CHECKS) begin : gen_fifo_status
        APLC_RXFIFO_EMPTY_FULL_MUTEX: assert property (
            @(posedge clk) disable iff (!$isunknown(rst_n) && rst_n === 1'b0)
            !(rxfifo_empty && rxfifo_full)
        ) else `uvm_error("APLC_SPI_FIFO", "RXFIFO both empty and full");

        APLC_TXFIFO_EMPTY_FULL_MUTEX: assert property (
            @(posedge clk) disable iff (!$isunknown(rst_n) && rst_n === 1'b0)
            !(txfifo_empty && txfifo_full)
        ) else `uvm_error("APLC_SPI_FIFO", "TXFIFO both empty and full");

        APLC_RXFIFO_FULL_COVER: cover property (
            @(posedge clk) disable iff (!$isunknown(rst_n) && rst_n === 1'b0)
            $rose(rxfifo_full)
        );

        APLC_TXFIFO_FULL_COVER: cover property (
            @(posedge clk) disable iff (!$isunknown(rst_n) && rst_n === 1'b0)
            $rose(txfifo_full)
        );
    end endgenerate

endinterface

`endif
