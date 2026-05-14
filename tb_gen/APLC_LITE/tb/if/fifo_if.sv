`ifndef FIFO_IF__SV
`define FIFO_IF__SV

interface fifo_if(
    input clk,
    input rst_n,
    input rxfifo_empty,
    input rxfifo_full,
    input txfifo_empty,
    input txfifo_full
);

    // AI gen: Clocking block for passive monitor
    clocking mon_cb @(posedge clk);
        input rxfifo_empty;
        input rxfifo_full;
        input txfifo_empty;
        input txfifo_full;
    endclocking

    `ifdef ASSERT_ON

    // AI gen: CHK_001 - Reset state: FIFOs must be empty after reset
    property p_reset_fifo_empty;
        @(posedge clk) !rst_n |-> (rxfifo_empty && txfifo_empty);
    endproperty
    assert_reset_fifo_empty: assert property (p_reset_fifo_empty)
        else $error("ASSERT: FIFO not empty during reset");

    // AI gen: FIFO empty and full are mutually exclusive
    property p_rx_fifo_exclusive;
        @(posedge clk) disable iff (!rst_n)
        !(rxfifo_empty && rxfifo_full);
    endproperty
    assert_rx_fifo_exclusive: assert property (p_rx_fifo_exclusive)
        else $error("ASSERT: RXFIFO both empty and full");

    property p_tx_fifo_exclusive;
        @(posedge clk) disable iff (!rst_n)
        !(txfifo_empty && txfifo_full);
    endproperty
    assert_tx_fifo_exclusive: assert property (p_tx_fifo_exclusive)
        else $error("ASSERT: TXFIFO both empty and full");

    `endif

endinterface

`endif
