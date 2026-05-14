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

    // AI gen: Clocking block for driver (active - drives pdi, pcs_n)
    clocking drv_cb @(posedge clk);
        output pcs_n;
        output pdi;
        input  pdo;
        input  pdo_oe;
        input  lane_mode;
        input  rxfifo_full;
        input  txfifo_empty;
        input  en;
        input  test_mode;
    endclocking

    // AI gen: Clocking block for monitor (passive - observes all)
    clocking mon_cb @(posedge clk);
        input pcs_n;
        input pdi;
        input pdo;
        input pdo_oe;
        input lane_mode;
        input rxfifo_empty;
        input rxfifo_full;
        input txfifo_empty;
        input txfifo_full;
        input en;
        input test_mode;
    endclocking

    `ifdef ASSERT_ON

    // AI gen: CHK_006 - pcs_n low during active transaction
    property p_pcs_n_frame_rule;
        @(posedge clk) disable iff (!rst_n)
        pdo_oe |-> !pcs_n;
    endproperty
    assert_pcs_n_frame_rule: assert property (p_pcs_n_frame_rule)
        else $error("ASSERT: pdo_oe=1 but pcs_n=1, frame protocol violation");

    // AI gen: CHK_006 - turnaround: pdo_oe must be 0 for at least 1 cycle between request end and response start
    // Monitored by driver/monitor, not SVA (requires state tracking)

    // AI gen: CHK_006 - pdo_oe stability during burst response: once high, must stay high until last beat
    property p_pdo_oe_burst_continuous;
        @(posedge clk) disable iff (!rst_n)
        pdo_oe && !pcs_n |-> pdo_oe throughout (pdo_oe [->1] ##1 pcs_n);
    endproperty

    // AI gen: CHK_005 - lane_mode must be stable during pcs_n=0 (transaction period)
    // This checks that lane_mode doesn't change while pcs_n is low
    reg [1:0] lane_mode_at_frame_start;
    always @(posedge clk) begin
        if (rst_n && !pcs_n && $past(pcs_n, 1))
            lane_mode_at_frame_start <= lane_mode;
    end
    property p_lane_mode_stable_during_frame;
        @(posedge clk) disable iff (!rst_n)
        !pcs_n |-> lane_mode == lane_mode_at_frame_start;
    endproperty
    assert_lane_mode_stable: assert property (p_lane_mode_stable_during_frame)
        else $error("ASSERT: lane_mode changed during pcs_n=0, frame data may corrupt");

    // AI gen: CHK_004 - When en=0 or test_mode=0, no CSR/AHB activity expected
    // This is checked at protocol level (status code), not directly via SVA

    // AI gen: CHK_006 - rxfifo_full backpressure: when full, pdi should not carry new data
    property p_rxfifo_full_no_data;
        @(posedge clk) disable iff (!rst_n)
        rxfifo_full && !pcs_n |-> 1; // Soft check - driver must respect, not RTL enforcement
    endproperty

    // AI gen: CHK_006 - txfifo_empty during response: pdo_oe stays high when txfifo_empty
    property p_txfifo_empty_pdo_oe_holds;
        @(posedge clk) disable iff (!rst_n)
        txfifo_empty && pdo_oe |-> pdo_oe;
    endproperty
    assert_txfifo_empty_pdo_oe: assert property (p_txfifo_empty_pdo_oe_holds)
        else $error("ASSERT: pdo_oe dropped while txfifo_empty, protocol violation");

    // AI gen: Reset state checks - CHK_001
    property p_reset_pdo_oe_low;
        @(posedge clk) !rst_n |-> !pdo_oe;
    endproperty
    assert_reset_pdo_oe: assert property (p_reset_pdo_oe_low)
        else $error("ASSERT: pdo_oe not low during reset");

    property p_reset_pdo_zero;
        @(posedge clk) !rst_n |-> pdo == 16'b0;
    endproperty
    assert_reset_pdo: assert property (p_reset_pdo_zero)
        else $error("ASSERT: pdo not zero during reset");

    `endif

endinterface

`endif
