// APLC SPI Interface with SVA assertions
`ifndef APLC_SPI_IF_SV
`define APLC_SPI_IF_SV

interface aplc_spi_if (
    input  logic        clk,
    input  logic        rst_n
);

    // SPI-like signals (VIP drives inputs, monitors outputs)
    logic        pcs_n;       // frame chip select, active-low
    logic [15:0] pdi;         // parallel data input
    logic [15:0] pdo;         // parallel data output
    logic        pdo_oe;      // output enable
    logic [1:0]  lane_mode;   // lane mode selection
    logic        en;          // module enable
    logic        test_mode;   // test mode enable

    // FIFO status signals
    logic        rxfifo_empty;
    logic        rxfifo_full;
    logic        txfifo_empty;
    logic        txfifo_full;

    // Clocking blocks
    // Driver clocking block - active at clock edge
    clocking drv_cb @(posedge clk);
        output  pcs_n, pdi, lane_mode, en, test_mode;
        input   pdo, pdo_oe;
        input   rxfifo_empty, rxfifo_full, txfifo_empty, txfifo_full;
    endclocking

    // Monitor clocking block - samples at clock edge
    clocking mon_cb @(posedge clk);
        input  pcs_n, pdi, pdo, pdo_oe, lane_mode, en, test_mode;
        input  rxfifo_empty, rxfifo_full, txfifo_empty, txfifo_full;
    endclocking

    // SVA Assertions

    // CHK_001: After reset, pdo_oe must be 0
    property p_reset_pdo_oe;
        @(posedge clk) !rst_n |=> pdo_oe == 1'b0;
    endproperty
    assert property (p_reset_pdo_oe)
        else $error("APLC_SPI SVA: pdo_oe not 0 after reset");

    // CHK_005: lane_mode stability during transaction (pcs_n=0)
    // lane_mode must not change while pcs_n is low
    property p_lane_mode_stable_during_txn;
        @(posedge clk) disable iff (!rst_n)
        (pcs_n == 1'b0) |=> $stable(lane_mode);
    endproperty
    assert property (p_lane_mode_stable_during_txn)
        else $warning("APLC_SPI SVA: lane_mode changed during transaction (pcs_n=0)");

    // CHK_006: turnaround - pdo_oe must be 0 for at least 1 cycle before response
    // After pcs_n goes low and before pdo_oe goes high, there must be a gap
    property p_turnaround_before_response;
        @(posedge clk) disable iff (!rst_n)
        $fell(pdo_oe) |=> pdo_oe == 1'b0 throughout ($fell(pcs_n) [=1]);
    endproperty

    // CHK_006: pdo_oe must be low when pcs_n is high (idle)
    property p_pdo_oe_idle;
        @(posedge clk) disable iff (!rst_n)
        (pcs_n == 1'b1) |-> (pdo_oe == 1'b0);
    endproperty
    assert property (p_pdo_oe_idle)
        else $error("APLC_SPI SVA: pdo_oe high while pcs_n high (idle)");

    // CHK_006: Half-duplex check - pdi should not be driven when pdo_oe is high
    // This is a protocol-level check, not enforceable on wires (input vs output)
    // but we can check that DUT does not drive pdo when pdo_oe is low
    property p_pdo_stable_when_oe_low;
        @(posedge clk) disable iff (!rst_n)
        (pdo_oe == 1'b0) |-> $stable(pdo);
    endproperty

    // CHK_014: rxfifo_full stalls receiver - when rxfifo_full=1,
    // pdi data should not be consumed (protocol-level, checked by monitor)

    // Cover properties
    cover property (@(posedge clk) disable iff (!rst_n) pcs_n == 1'b0);
    cover property (@(posedge clk) disable iff (!rst_n) pdo_oe == 1'b1);
    cover property (@(posedge clk) disable iff (!rst_n) rxfifo_full == 1'b1);
    cover property (@(posedge clk) disable iff (!rst_n) txfifo_empty == 1'b1);
    cover property (@(posedge clk) disable iff (!rst_n) lane_mode == APLC_LANE_1BIT);
    cover property (@(posedge clk) disable iff (!rst_n) lane_mode == APLC_LANE_4BIT);
    cover property (@(posedge clk) disable iff (!rst_n) lane_mode == APLC_LANE_8BIT);
    cover property (@(posedge clk) disable iff (!rst_n) lane_mode == APLC_LANE_16BIT);

endinterface

`endif
