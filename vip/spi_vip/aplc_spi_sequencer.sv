// APLC SPI VIP Sequencer

`ifndef APLC_SPI_SEQUENCER_SV
`define APLC_SPI_SEQUENCER_SV

class aplc_spi_sequencer extends uvm_sequencer #(aplc_spi_item);

    `uvm_component_utils(aplc_spi_sequencer)

    aplc_spi_agent_config m_cfg;
    virtual aplc_spi_if   m_vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(aplc_spi_agent_config)::get(this, "", "agent_config", m_cfg)) begin
            `uvm_warning("APLC_SPI_SQR", "Cannot get agent_config")
        end else begin
            m_vif = m_cfg.get_vif();
        end
    endfunction

endclass

`endif
