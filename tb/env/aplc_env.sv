// APLC Testbench Environment

`ifndef APLC_ENV_SV
`define APLC_ENV_SV

import aplc_spi_pkg::*;
import yuu_common_pkg::*;
import yuu_ahb_pkg::*;

class aplc_env extends uvm_env;

    `uvm_component_utils(aplc_env)

    aplc_env_config m_cfg;

    aplc_spi_agent     m_spi_agent;
    yuu_ahb_slave_agent m_ahb_slave;
    aplc_csr_file      m_csr_file;

    uvm_analysis_port #(aplc_spi_mon_item) spi_mon_port;

    yuu_ahb_slave_response_sequence ahb_resp_seq;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db#(aplc_env_config)::get(this, "", "env_config", m_cfg)) begin
            `uvm_fatal("APLC_ENV", "Cannot get env_config")
        end

        // SPI agent
        if (m_cfg.has_spi_agent) begin
            uvm_config_db#(aplc_spi_agent_config)::set(this, "m_spi_agent*", "agent_config", m_cfg.spi_cfg);
            m_spi_agent = aplc_spi_agent::type_id::create("m_spi_agent", this);
        end

        // CSR file
        if (m_cfg.has_csr_file) begin
            uvm_config_db#(virtual aplc_csr_if)::set(this, "m_csr_file*", "csr_vif", m_cfg.csr_vif);
            m_csr_file = aplc_csr_file::type_id::create("m_csr_file", this);
        end

        // AHB slave agent
        if (m_cfg.has_ahb_agent) begin
            uvm_config_db#(yuu_ahb_slave_config)::set(this, "m_ahb_slave*", "cfg", m_cfg.ahb_cfg);
            m_ahb_slave = yuu_ahb_slave_agent::type_id::create("m_ahb_slave", this);
        end

        spi_mon_port = new("spi_mon_port", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        if (m_spi_agent != null) begin
            m_spi_agent.out_port.connect(spi_mon_port);
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        if (m_ahb_slave != null) begin
            ahb_resp_seq = yuu_ahb_slave_response_sequence::type_id::create("ahb_resp_seq");
            ahb_resp_seq.start(m_ahb_slave.sequencer);
        end
    endtask

endclass

`endif
