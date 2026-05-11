/******************************************************************************
 * SPI VIP Agent Configuration
 * Description: Configuration class for SPI agent
 ******************************************************************************/

`ifndef SPI_AGENT_CONFIG_SV
`define SPI_AGENT_CONFIG_SV

class spi_agent_config extends uvm_component;

    `uvm_component_utils(spi_agent_config)

    protected uvm_active_passive_enum is_active = UVM_ACTIVE;
    protected bit has_coverage = 1;
    protected bit has_checks = 1;

    protected spi_vif_t dut_vif;
    protected bit reset_active_level = 0;

    protected int unsigned driving_delay = 0;
    protected int unsigned turnaround_cycles = 1;

    protected bit en_protocol_checks = 1;
    protected bit en_x_z_checks = 1;
    protected bit en_timeout_checks = 1;

    protected int unsigned bus_timeout_cycles = 256;

    function new(string name = "spi_agent_config", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function uvm_active_passive_enum get_is_active();
        return is_active;
    endfunction

    virtual function void set_is_active(uvm_active_passive_enum value);
        is_active = value;
    endfunction

    virtual function bit get_has_coverage();
        return has_coverage;
    endfunction

    virtual function void set_has_coverage(bit value);
        has_coverage = value;
    endfunction

    virtual function bit get_has_checks();
        return has_checks;
    endfunction

    virtual function void set_has_checks(bit value);
        has_checks = value;
    endfunction

    virtual function spi_vif_t get_dut_vif();
        return dut_vif;
    endfunction

    virtual function void set_dut_vif(spi_vif_t value);
        dut_vif = value;
    endfunction

    virtual function bit get_reset_active_level();
        return reset_active_level;
    endfunction

    virtual function void set_reset_active_level(bit value);
        reset_active_level = value;
    endfunction

    virtual function int unsigned get_driving_delay();
        return driving_delay;
    endfunction

    virtual function void set_driving_delay(int unsigned value);
        driving_delay = value;
    endfunction

    virtual function int unsigned get_turnaround_cycles();
        return turnaround_cycles;
    endfunction

    virtual function void set_turnaround_cycles(int unsigned value);
        turnaround_cycles = value;
    endfunction

    virtual function bit get_en_protocol_checks();
        return en_protocol_checks;
    endfunction

    virtual function void set_en_protocol_checks(bit value);
        en_protocol_checks = value;
        if(dut_vif != null) begin
            dut_vif.en_protocol_checks = value;
        end
    endfunction

    virtual function bit get_en_x_z_checks();
        return en_x_z_checks;
    endfunction

    virtual function void set_en_x_z_checks(bit value);
        en_x_z_checks = value;
        if(dut_vif != null) begin
            dut_vif.en_x_z_checks = value;
        end
    endfunction

    virtual function int unsigned get_bus_timeout_cycles();
        return bus_timeout_cycles;
    endfunction

    virtual function void set_bus_timeout_cycles(int unsigned value);
        bus_timeout_cycles = value;
    endfunction

    virtual task wait_reset_start();
        if(reset_active_level == 0) begin
            @(negedge dut_vif.reset_n);
        end else begin
            @(posedge dut_vif.reset_n);
        end
    endtask

    virtual task wait_reset_end();
        if(reset_active_level == 0) begin
            @(posedge dut_vif.reset_n);
        end else begin
            @(negedge dut_vif.reset_n);
        end
    endtask

    virtual function string get_id();
        return "SPI_CFG";
    endfunction

    virtual function void start_of_simulation_phase(input uvm_phase phase);
        super.start_of_simulation_phase(phase);

        assert(dut_vif != null) else
            `uvm_fatal(get_id(), "DUT interface is null - set via set_dut_vif() before simulation");

        dut_vif.en_protocol_checks = en_protocol_checks;
        dut_vif.en_x_z_checks = en_x_z_checks;
        dut_vif.has_checks = has_checks;
    endfunction

endclass

`endif
