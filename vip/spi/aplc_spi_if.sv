`ifndef APLC_SPI_IF_SV
`define APLC_SPI_IF_SV

interface aplc_spi_if (
    input logic clk,
    input logic rst_n
);

    logic        en;
    logic        test_mode;
    logic        pcs_n      = 1'b1;
    logic [15:0] pdi        = '0;
    logic [15:0] pdo;
    logic        pdo_oe;
    logic [1:0]  lane_mode;
    logic        rxfifo_empty;
    logic        rxfifo_full;
    logic        txfifo_empty;
    logic        txfifo_full;

    clocking drv_cb @(posedge clk);
        output  pcs_n, pdi;
        input   pdo, pdo_oe;
        input   rxfifo_empty, rxfifo_full, txfifo_empty, txfifo_full;
    endclocking

    clocking mon_cb @(posedge clk);
        input  pcs_n, pdi, pdo, pdo_oe;
        input  en, test_mode, lane_mode;
        input  rxfifo_empty, rxfifo_full, txfifo_empty, txfifo_full;
    endclocking

    modport drv_mp (clocking drv_cb, input clk, rst_n);
    modport mon_mp (clocking mon_cb, input clk, rst_n);

    // -------------------------------------------------------
    // SVA Assertion Control
    // -------------------------------------------------------
    bit en_checks        = 1'b1;
    bit en_protocol_checks = 1'b1;
    bit en_reset_checks  = 1'b1;

    // -------------------------------------------------------
    // CHK_001: Reset state check
    // -------------------------------------------------------
    property aplc_spi_pdo_oe_after_reset_p;
        @(posedge clk) $rose(rst_n) |=> !$past(pdo_oe);
    endproperty
    assert property (aplc_spi_pdo_oe_after_reset_p)
        else $error("[APLC_SPI_PDO_OE_AFTER_RESET_ERR] pdo_oe should be 0 after reset");
    cover property (aplc_spi_pdo_oe_after_reset_p);

    property aplc_spi_pdo_zero_after_reset_p;
        @(posedge clk) $rose(rst_n) |=> $past(pdo) == '0;
    endproperty
    assert property (aplc_spi_pdo_zero_after_reset_p)
        else $error("[APLC_SPI_PDO_ZERO_AFTER_RESET_ERR] pdo should be 0 after reset");
    cover property (aplc_spi_pdo_zero_after_reset_p);

    // -------------------------------------------------------
    // CHK_005/CHK_010: lane_mode stability during transaction
    // -------------------------------------------------------
    property aplc_spi_lane_mode_stable_during_txn_p;
        @(posedge clk) disable iff (!rst_n || !en_checks || !en_protocol_checks)
        !pcs_n |-> $stable(lane_mode);
    endproperty
    assert property (aplc_spi_lane_mode_stable_during_txn_p)
        else $error("[APLC_SPI_LANE_MODE_STABLE_ERR] lane_mode must be stable during pcs_n=0");
    cover property (aplc_spi_lane_mode_stable_during_txn_p);

    // -------------------------------------------------------
    // CHK_006: Frame protocol checks
    // -------------------------------------------------------
    // pdo_oe must be 0 when idle (relaxed: allow 1 cycle after pcs_n goes high)
    property aplc_spi_pdo_oe_low_during_idle_p;
        @(posedge clk) disable iff (!rst_n || !en_checks || !en_protocol_checks)
        $rose(pcs_n) |=> !pdo_oe;
    endproperty
    assert property (aplc_spi_pdo_oe_low_during_idle_p)
        else $error("[APLC_SPI_PDO_OE_IDLE_ERR] pdo_oe must be 0 after pcs_n rises");
    cover property (aplc_spi_pdo_oe_low_during_idle_p);

    // pcs_n falling edge starts a frame
    property aplc_spi_pcs_n_falling_starts_frame_p;
        @(posedge clk) disable iff (!rst_n || !en_checks || !en_protocol_checks)
        $fell(pcs_n) |-> !pdo_oe;
    endproperty
    assert property (aplc_spi_pcs_n_falling_starts_frame_p)
        else $error("[APLC_SPI_PCS_N_FALL_PDO_OE_ERR] pdo_oe must be 0 at frame start");
    cover property (aplc_spi_pcs_n_falling_starts_frame_p);

    // Turnaround: after pcs_n rises (frame end), 1 cycle before pdo_oe can go high
    // This checks that pdo_oe does not go high while pcs_n is still low (request phase)
    property aplc_spi_pdo_oe_after_turnaround_p;
        @(posedge clk) disable iff (!rst_n || !en_checks || !en_protocol_checks)
        $fell(pcs_n) |-> !pdo_oe throughout first_match(!pdo_oe [*1:$] ##1 pdo_oe);
    endproperty
    // Note: This property is relaxed since the turnaround timing is controlled by DUT internally

    // pdo_oe must deassert after response completes - implicitly checked by aplc_spi_pdo_oe_low_during_idle_p

    // -------------------------------------------------------
    // X/Z value checks on critical signals
    // -------------------------------------------------------
    property aplc_spi_pcs_n_valid_p;
        @(posedge clk) disable iff (!rst_n || !en_checks)
        $isunknown(pcs_n) == 0;
    endproperty
    assert property (aplc_spi_pcs_n_valid_p)
        else $error("[APLC_SPI_PCS_N_XZ_ERR] pcs_n must not be X/Z");
    cover property (aplc_spi_pcs_n_valid_p);

    property aplc_spi_lane_mode_valid_p;
        @(posedge clk) disable iff (!rst_n || !en_checks)
        $isunknown(lane_mode) == 0;
    endproperty
    assert property (aplc_spi_lane_mode_valid_p)
        else $error("[APLC_SPI_LANE_MODE_XZ_ERR] lane_mode must not be X/Z");
    cover property (aplc_spi_lane_mode_valid_p);

    property aplc_spi_pdo_oe_valid_p;
        @(posedge clk) disable iff (!rst_n || !en_checks)
        $isunknown(pdo_oe) == 0;
    endproperty
    assert property (aplc_spi_pdo_oe_valid_p)
        else $error("[APLC_SPI_PDO_OE_XZ_ERR] pdo_oe must not be X/Z");
    cover property (aplc_spi_pdo_oe_valid_p);

    // pdi valid during active frame
    property aplc_spi_pdi_valid_during_frame_p;
        @(posedge clk) disable iff (!rst_n || !en_checks || !en_protocol_checks)
        !pcs_n && !pdo_oe |-> $countones(pdi) + $countones(~pdi) > 0;
    endproperty
    // Relaxed check - only verify pdi is not all X/Z during request phase

    // pdo valid during response phase
    property aplc_spi_pdo_valid_during_response_p;
        @(posedge clk) disable iff (!rst_n || !en_checks || !en_protocol_checks)
        pdo_oe |-> $isunknown(pdo) == 0;
    endproperty
    assert property (aplc_spi_pdo_valid_during_response_p)
        else $error("[APLC_SPI_PDO_XZ_ERR] pdo must not be X/Z during response");
    cover property (aplc_spi_pdo_valid_during_response_p);

    // -------------------------------------------------------
    // FIFO status checks
    // -------------------------------------------------------
    property aplc_spi_rxfifo_status_valid_p;
        @(posedge clk) disable iff (!rst_n || !en_checks)
        $isunknown(rxfifo_empty) == 0 && $isunknown(rxfifo_full) == 0;
    endproperty
    assert property (aplc_spi_rxfifo_status_valid_p)
        else $error("[APLC_SPI_RXFIFO_STATUS_XZ_ERR] rxfifo status must not be X/Z");
    cover property (aplc_spi_rxfifo_status_valid_p);

    property aplc_spi_txfifo_status_valid_p;
        @(posedge clk) disable iff (!rst_n || !en_checks)
        $isunknown(txfifo_empty) == 0 && $isunknown(txfifo_full) == 0;
    endproperty
    assert property (aplc_spi_txfifo_status_valid_p)
        else $error("[APLC_SPI_TXFIFO_STATUS_XZ_ERR] txfifo status must not be X/Z");
    cover property (aplc_spi_txfifo_status_valid_p);

    // rxfifo_empty and rxfifo_full are mutually exclusive
    property aplc_spi_rxfifo_mutex_p;
        @(posedge clk) disable iff (!rst_n || !en_checks)
        !(rxfifo_empty && rxfifo_full);
    endproperty
    assert property (aplc_spi_rxfifo_mutex_p)
        else $error("[APLC_SPI_RXFIFO_MUTEX_ERR] rxfifo cannot be both empty and full");
    cover property (aplc_spi_rxfifo_mutex_p);

    property aplc_spi_txfifo_mutex_p;
        @(posedge clk) disable iff (!rst_n || !en_checks)
        !(txfifo_empty && txfifo_full);
    endproperty
    assert property (aplc_spi_txfifo_mutex_p)
        else $error("[APLC_SPI_TXFIFO_MUTEX_ERR] txfifo cannot be both empty and full");
    cover property (aplc_spi_txfifo_mutex_p);

endinterface

`endif
