/******************************************************************************
 * SPI VIP Interface
 * Description: SPI interface for APLC-Lite external test interface
 ******************************************************************************/

`ifndef SPI_IF_SV
`define SPI_IF_SV

`ifndef SPI_MAX_DATA_WIDTH
`define SPI_MAX_DATA_WIDTH 32
`endif

`ifndef SPI_MAX_ADDR_WIDTH
`define SPI_MAX_ADDR_WIDTH 32
`endif

interface spi_if(input clk);
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    logic reset_n;

    logic pcs_n;
    logic [15:0] pdi;
    logic [15:0] pdo;
    logic pdo_oe;
    logic [1:0] lane_mode;
    logic en;
    logic test_mode;

    logic rxfifo_empty;
    logic rxfifo_full;
    logic txfifo_empty;
    logic txfifo_full;

    bit has_checks = 1;
    bit en_protocol_checks = 1;
    bit en_x_z_checks = 1;

    property spi_pcs_n_valid_values_p;
        @(posedge clk) disable iff(!reset_n || !en_x_z_checks)
            $isunknown(pcs_n) == 0;
    endproperty
    SPI_ILLEGAL_PCS_N_VALUE_ERR: assert property (spi_pcs_n_valid_values_p) else
        `uvm_error("SPI_IF", $sformatf("[%0t] Found illegal pcs_n value", $time))

    property spi_pdi_valid_values_p;
        @(posedge clk) disable iff(!reset_n || !en_x_z_checks || pcs_n)
            $isunknown(pdi) == 0;
    endproperty
    SPI_ILLEGAL_PDI_VALUE_ERR: assert property (spi_pdi_valid_values_p) else
        `uvm_error("SPI_IF", $sformatf("[%0t] Found illegal pdi value", $time))

    property spi_lane_mode_stable_during_transaction_p;
        @(posedge clk) disable iff(!reset_n || !en_protocol_checks)
            !pcs_n |-> $stable(lane_mode);
    endproperty
    SPI_LANE_MODE_CHANGE_DURING_TRANSACTION_ERR: assert property (spi_lane_mode_stable_during_transaction_p) else
        `uvm_error("SPI_IF", $sformatf("[%0t] lane_mode changed during transaction", $time))

    property spi_pdo_oe_during_response_p;
        @(posedge clk) disable iff(!reset_n || !en_protocol_checks)
            pdo_oe |-> !pcs_n;
    endproperty
    SPI_PDO_OE_WITHOUT_TRANSACTION_ERR: assert property (spi_pdo_oe_during_response_p) else
        `uvm_error("SPI_IF", $sformatf("[%0t] pdo_oe asserted without active transaction", $time))

    clocking cb @(posedge clk);
        default input #1step output #0;
        input pdo, pdo_oe;
        input rxfifo_empty, rxfifo_full, txfifo_empty, txfifo_full;
        output pcs_n, pdi, lane_mode, en, test_mode;
    endclocking

    clocking cb_mon @(posedge clk);
        default input #1step output #0;
        input pcs_n, pdi, pdo, pdo_oe, lane_mode, en, test_mode;
        input rxfifo_empty, rxfifo_full, txfifo_empty, txfifo_full;
    endclocking

    modport master(clocking cb, output reset_n);
    modport monitor(clocking cb_mon, input reset_n);
    modport slave(input clk, reset_n, pcs_n, pdi, lane_mode, en, test_mode,
                  output pdo, pdo_oe, rxfifo_empty, rxfifo_full, txfifo_empty, txfifo_full);

endinterface

`endif
