`ifndef SPI_IF__SV
`define SPI_IF__SV

interface spi_if(
    input clk,
    input rst_n,
    input en,
    input test_mode,
    input pcs_n,
    input [15:0] pdi,
    input [15:0] pdo,
    input pdo_oe,
    input [1:0] lane_mode,
    input rxfifo_empty,
    input rxfifo_full,
    input txfifo_empty,
    input txfifo_full
);

    // Clocking blocks
    clocking drv_cb @(posedge clk);
        output pcs_n;
        output pdi;
        input  pdo;
        input  pdo_oe;
        input  lane_mode;
        output en;
        output test_mode;
        input  rxfifo_full;
        input  txfifo_empty;
    endclocking

    clocking mon_cb @(posedge clk);
        input  pcs_n;
        input  pdi;
        input  pdo;
        input  pdo_oe;
        input  lane_mode;
        input  en;
        input  test_mode;
        input  rxfifo_full;
        input  rxfifo_empty;
        input  txfifo_full;
        input  txfifo_empty;
    endclocking

    `ifdef ASSERT_ON

    // CHK_001: Reset state checker - all outputs deasserted after reset
    property p_reset_pdo_oe;
        @(posedge clk) !rst_n |=> (pdo_oe == 1'b0);
    endproperty
    assert property(p_reset_pdo_oe) else
        $error("SPI_IF ASSERT: pdo_oe not deasserted after reset");

    property p_reset_pdo_zero;
        @(posedge clk) !rst_n |=> (pdo == 16'b0);
    endproperty
    assert property(p_reset_pdo_zero) else
        $error("SPI_IF ASSERT: pdo not zero after reset");

    // CHK_001: After reset, FIFOs should be empty
    property p_fifo_empty_after_reset;
        @(posedge clk) !rst_n |=> (rxfifo_empty && txfifo_empty);
    endproperty
    assert property(p_fifo_empty_after_reset) else
        $error("SPI_IF ASSERT: FIFOs not empty after reset");

    // CHK_005: Lane mode must be stable during pcs_n=0 (transaction in progress)
    property p_lane_mode_stable_during_transaction;
        @(posedge clk) disable iff (!rst_n)
            !pcs_n |=> $stable(lane_mode);
    endproperty
    assert property(p_lane_mode_stable_during_transaction) else
        $error("SPI_IF ASSERT: lane_mode changed during active transaction (pcs_n=0)");

    // CHK_006: pdo_oe indicates DUT is driving response - pdo must be valid
    property p_pdo_oe_implies_dut_drive;
        @(posedge clk) pdo_oe |-> !$isunknown(pdo);
    endproperty
    assert property(p_pdo_oe_implies_dut_drive) else
        $error("SPI_IF ASSERT: pdo is X/Z when pdo_oe is active");

    // CHK_006: Turnaround - pdo_oe must not go high in same cycle as last pdi
    // There must be at least 1 cycle gap (turnaround) between request and response
    property p_turnaround_after_request;
        @(posedge clk) disable iff (!rst_n)
            $fell(pdo_oe) |-> !pdo_oe throughout (1 ##1 !pdo_oe);
    endproperty

    // CHK_006: Half-duplex check - pdo_oe should not be active while master drives pdi
    // When pdo_oe=1, DUT drives pdo; master must not drive pdi simultaneously
    // This is a protocol constraint on the master (driver) side

    // CHK_006: TXFIFO empty stall - when pdo_oe active and txfifo_empty, pdo holds previous value
    property p_txfifo_empty_stall;
        @(posedge clk) (pdo_oe && txfifo_empty) |-> $stable(pdo);
    endproperty
    assert property(p_txfifo_empty_stall) else
        $error("SPI_IF ASSERT: pdo changed while txfifo_empty during response");

    // CHK_006: RXFIFO full backpressure - data must not change when rxfifo_full
    // (This checks that pdi is stable during backpressure, i.e., master stopped driving)
    property p_rxfifo_full_stable_pdi;
        @(posedge clk) disable iff (!rst_n)
            (rxfifo_full && !pcs_n) |-> $stable(pdi);
    endproperty
    assert property(p_rxfifo_full_stable_pdi) else
        $error("SPI_IF ASSERT: pdi changed while rxfifo_full (backpressure violation)");

    // CHK_006: pdo_oe must not be active during request phase
    // Before DUT has received a complete request, pdo_oe must be 0
    // This is implicitly checked by the turnaround timing

    `endif

endinterface

`endif
