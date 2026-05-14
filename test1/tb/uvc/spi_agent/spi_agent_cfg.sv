`ifndef SPI_AGENT_CFG_SV
`define SPI_AGENT_CFG_SV

class spi_agent_cfg extends uvm_object;
    bit enable_monitor = 1;
    bit is_active = 1;

    spi_lane_mode_e lane_mode = LANE_MODE_16BIT;
    bit en = 1;
    bit test_mode = 1;

    `uvm_object_utils(spi_agent_cfg)

    function new(string name = "spi_agent_cfg");
        super.new(name);
    endfunction

    virtual function int get_lane_width();
        case(lane_mode)
            LANE_MODE_1BIT:  return 1;
            LANE_MODE_4BIT:  return 4;
            LANE_MODE_8BIT:  return 8;
            LANE_MODE_16BIT: return 16;
            default:         return 16;
        endcase
    endfunction

endclass : spi_agent_cfg

`endif
