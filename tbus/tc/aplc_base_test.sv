`ifndef APLC_BASE_TEST_SV
`define APLC_BASE_TEST_SV

class aplc_base_test extends uvm_test;

    `uvm_component_utils(aplc_base_test)

    aplc_env          m_env;
    aplc_env_config   m_env_cfg;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        m_env_cfg = aplc_env_config::type_id::create("m_env_cfg");

        // SPI agent config
        m_env_cfg.spi_cfg.is_active    = UVM_ACTIVE;
        m_env_cfg.spi_cfg.has_coverage = 1'b1;
        m_env_cfg.spi_cfg.has_checks   = 1'b1;
        begin
            virtual aplc_spi_if spi_vif;
            if (!uvm_config_db #(virtual aplc_spi_if)::get(this, "", "aplc_spi_if", spi_vif)) begin
                `uvm_fatal(get_id(), "Cannot get SPI interface from config_db")
            end
            m_env_cfg.spi_cfg.set_vif(spi_vif);
        end

        // AHB env config
        begin
            virtual yuu_ahb_interface ahb_vif;
            if (!uvm_config_db #(virtual yuu_ahb_interface)::get(this, "", "yuu_ahb_interface", ahb_vif)) begin
                `uvm_fatal(get_id(), "Cannot get AHB interface from config_db")
            end
            m_env_cfg.ahb_env_cfg.ahb_if = ahb_vif;
            m_env_cfg.ahb_env_cfg.events = new("events");

            // Configure one slave agent with full address range
            begin
                yuu_ahb_slave_config slv_cfg = yuu_ahb_slave_config::type_id::create("slv_cfg");
                yuu_common_addr_map addr_map;
                slv_cfg.index = 0;
                slv_cfg.is_active = UVM_ACTIVE;
                slv_cfg.coverage_enable = True;
                slv_cfg.wait_enable = False;
                slv_cfg.mem_init_pattern = PATTERN_ALL_0;
                addr_map = yuu_common_addr_map::type_id::create("addr_map");
                addr_map.set_map(32'h00000000, 32'hFFFFFFFF);
                slv_cfg.maps = new[1];
                slv_cfg.maps[0] = addr_map;
                m_env_cfg.ahb_env_cfg.set_config(slv_cfg);
            end
        end

        uvm_config_db #(aplc_env_config)::set(this, "m_env", "aplc_env_config", m_env_cfg);
        m_env = aplc_env::type_id::create("m_env", this);
    endfunction

    virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        phase.drop_objection(this);
    endtask

    protected virtual function string get_id();
        return "TEST";
    endfunction

endclass

`endif
