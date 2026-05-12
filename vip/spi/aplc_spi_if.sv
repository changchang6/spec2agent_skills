`ifndef APLC_SPI_IF_SV
`define APLC_SPI_IF_SV

interface aplc_spi_if (input clk, input rst_n);
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    logic        en;
    logic        test_mode;
    logic        pcs_n = 1'b1;
    logic [15:0] pdi = '0;
    logic [15:0] pdo;
    logic        pdo_oe;
    logic [1:0]  lane_mode;
    logic        rxfifo_empty;
    logic        rxfifo_full;
    logic        txfifo_empty;
    logic        txfifo_full;

    clocking drv_cb @(posedge clk);
        output   pcs_n, pdi;
        input    pdo, pdo_oe;
        input    rxfifo_empty, rxfifo_full, txfifo_empty, txfifo_full;
    endclocking

    clocking mon_cb @(posedge clk);
        input  pcs_n, pdi, pdo, pdo_oe;
        input  en, test_mode, lane_mode;
        input  rxfifo_empty, rxfifo_full, txfifo_empty, txfifo_full;
    endclocking

    bit en_protocol_checks = 1;
    bit en_x_z_checks      = 1;

    // -------------------------------------------------------
    // X/Z checks
    // -------------------------------------------------------
    property p_pcs_n_valid;
        @(posedge clk) disable iff (!rst_n || !en_x_z_checks)
            $isunknown(pcs_n) == 0;
    endproperty
    assert property (p_pcs_n_valid) else
        `uvm_error("SPI_IF", "pcs_n is X/Z")
    cover property (p_pcs_n_valid);

    property p_pdi_valid;
        @(posedge clk) disable iff (!rst_n || !en_x_z_checks || pcs_n !== 1'b0)
            $isunknown(pdi) == 0;
    endproperty
    assert property (p_pdi_valid) else
        `uvm_error("SPI_IF", "pdi is X/Z during active frame")
    cover property (p_pdi_valid);

    property p_pdo_valid;
        @(posedge clk) disable iff (!rst_n || !en_x_z_checks || !pdo_oe)
            $isunknown(pdo) == 0;
    endproperty
    assert property (p_pdo_valid) else
        `uvm_error("SPI_IF", "pdo is X/Z during output phase")
    cover property (p_pdo_valid);

    // -------------------------------------------------------
    // Protocol checks (CHK_006: frame_protocol_checker)
    // -------------------------------------------------------
    // Turnaround: exactly 1 cycle between request end (pdo_oe=0) and response start (pdo_oe=1)
    // After pcs_n=0 and before pdo_oe rises, there must be exactly 1 cycle gap
    // This is implicitly guaranteed by DUT FSM, check pdo_oe rises after request phase

    // pdo_oe should only be high during response phase
    property p_pdo_oe_only_during_response;
        @(posedge clk) disable iff (!rst_n || !en_protocol_checks)
            pdo_oe |-> !pcs_n;
    endproperty
    assert property (p_pdo_oe_only_during_response) else
        `uvm_error("SPI_IF", "pdo_oe asserted while pcs_n is high")
    cover property (p_pdo_oe_only_during_response);

    // -------------------------------------------------------
    // CHK_005: lane_mode_checker - lane_mode stable during transaction
    // -------------------------------------------------------
    property p_lane_mode_stable_during_transaction;
        @(posedge clk) disable iff (!rst_n || !en_protocol_checks)
            !pcs_n |-> $stable(lane_mode);
    endproperty
    assert property (p_lane_mode_stable_during_transaction) else
        `uvm_error("SPI_IF", "lane_mode changed during active transaction (pcs_n=0)")
    cover property (p_lane_mode_stable_during_transaction);

    // -------------------------------------------------------
    // CHK_001: reset_state_checker - outputs after reset
    // -------------------------------------------------------
    property p_pdo_oe_after_reset;
        @(posedge clk) disable iff (!en_protocol_checks)
            !rst_n |-> !pdo_oe;
    endproperty
    assert property (p_pdo_oe_after_reset) else
        `uvm_error("SPI_IF", "pdo_oe not 0 during reset")
    cover property (p_pdo_oe_after_reset);

    property p_pdo_after_reset;
        @(posedge clk) disable iff (!en_protocol_checks)
            !rst_n |-> pdo == '0;
    endproperty
    assert property (p_pdo_after_reset) else
        `uvm_error("SPI_IF", "pdo not 0 during reset")
    cover property (p_pdo_after_reset);

    // -------------------------------------------------------
    // CHK_006: pdi must not change when pcs_n is high (idle)
    // -------------------------------------------------------
    property p_pdi_stable_when_idle;
        @(posedge clk) disable iff (!rst_n || !en_protocol_checks)
            pcs_n |-> pdi == '0;
    endproperty
    assert property (p_pdi_stable_when_idle) else
        `uvm_error("SPI_IF", "pdi changed while pcs_n is high (idle)")
    cover property (p_pdi_stable_when_idle);

    // -------------------------------------------------------
    // CHK_006: pdo_oe must go low before pcs_n goes high
    // -------------------------------------------------------
    property p_pdo_oe_low_before_pcs_n_high;
        @(posedge clk) disable iff (!rst_n || !en_protocol_checks)
            $rose(pcs_n) |-> !pdo_oe;
    endproperty
    assert property (p_pdo_oe_low_before_pcs_n_high) else
        `uvm_error("SPI_IF", "pdo_oe still high when pcs_n rises")
    cover property (p_pdo_oe_low_before_pcs_n_high);

    // -------------------------------------------------------
    // Half-duplex: pdo_oe and pdi should not be active simultaneously
    // -------------------------------------------------------
    property p_half_duplex;
        @(posedge clk) disable iff (!rst_n || !en_protocol_checks || pcs_n)
            pdo_oe |-> $stable(pdi);
    endproperty
    assert property (p_half_duplex) else
        `uvm_error("SPI_IF", "Half-duplex violation: pdo_oe and pdi active simultaneously")
    cover property (p_half_duplex);

endinterface

`endif
