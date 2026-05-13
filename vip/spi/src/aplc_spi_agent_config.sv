// APLC SPI Agent configuration
`ifndef APLC_SPI_AGENT_CONFIG_SV
`define APLC_SPI_AGENT_CONFIG_SV

class aplc_spi_agent_config extends uvm_object;

    // Active/passive mode
    uvm_active_passive_enum m_is_active = UVM_ACTIVE;

    // Interface handle
    virtual aplc_spi_if m_vif;

    // Default lane mode for driver
    rand aplc_lane_mode_e lane_mode;

    // Module enable and test mode
    rand bit en;
    rand bit test_mode;

    // Error injection controls
    rand bit inject_bad_opcode;    // send illegal opcode
    rand bit inject_frame_abort;   // release pcs_n early
    rand bit inject_lane_change;   // change lane_mode mid-txn

    `uvm_object_utils(aplc_spi_agent_config)

    function new(string name = "aplc_spi_agent_config");
        super.new(name);
        en        = 1'b1;
        test_mode = 1'b1;
        lane_mode = APLC_LANE_16BIT;
        inject_bad_opcode  = 1'b0;
        inject_frame_abort = 1'b0;
        inject_lane_change = 1'b0;
    endfunction

    constraint c_lane_mode {
        lane_mode inside {APLC_LANE_1BIT, APLC_LANE_4BIT,
                         APLC_LANE_8BIT, APLC_LANE_16BIT};
    }

endclass

`endif
