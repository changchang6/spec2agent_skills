# SPI VIP for APLC-Lite

## Overview

This VIP models the ATE (Automated Test Equipment) side of the APLC-Lite class-SPI half-duplex test interface. It supports all 6 command opcodes, 4 lane modes, burst transfers, and error scenarios.

## File Structure

```
vip/spi_vip/
├── spi_if.sv            # SystemVerilog interface with clocking blocks
├── spi_types.sv         # Type definitions (enums, typedefs)
├── spi_item.sv          # Base sequence item (transaction)
├── spi_mon_item.sv      # Monitor item with timing/observability fields
├── spi_drv_item.sv      # Driver item with delay/abort controls
├── spi_agent_config.sv  # Agent configuration (extends uvm_component)
├── spi_monitor.sv       # Protocol monitor
├── spi_driver.sv        # ATE-side driver
├── spi_sequencer.sv     # Sequencer
├── spi_coverage.sv      # Functional coverage collector
├── spi_agent.sv         # Agent (combines all components)
├── spi_seq_lib.sv       # Sequence library
└── spi_pkg.sv           # Package (includes all files)
```

## Integration

### 1. Compile Order

```makefile
# The interface file is included outside the package via `include in spi_pkg.sv
# Compile spi_pkg.sv, which pulls in all other files
spi_pkg.sv
```

Add `+incdir+<path_to_spi_vip>` to your VCS compile options.

### 2. Interface Instantiation

Instantiate the interface in your testbench top module:

```systemverilog
spi_if spi_vif(.clk(clk));
assign spi_vif.rst_n = rst_n;

// Connect to DUT
APLC_LITE u_dut (
  .pcs_n_i       (spi_vif.pcs_n),
  .pdi_i         (spi_vif.pdi),
  .pdo_o         (spi_vif.pdo),
  .pdo_oe_o      (spi_vif.pdo_oe),
  .lane_mode_i   (spi_vif.lane_mode),
  .en_i          (spi_vif.en),
  .test_mode_i   (spi_vif.test_mode),
  .rxfifo_empty_o(spi_vif.rxfifo_empty),
  .rxfifo_full_o (spi_vif.rxfifo_full),
  .txfifo_empty_o(spi_vif.txfifo_empty),
  .txfifo_full_o (spi_vif.txfifo_full),
  ...
);
```

### 3. Configuration

Set the virtual interface and agent config in your test:

```systemverilog
// Create agent config
spi_agent_config spi_cfg = spi_agent_config::type_id::create("spi_cfg", this);
spi_cfg.set_is_active(UVM_ACTIVE);
spi_cfg.set_has_coverage(1);
spi_cfg.set_vif(spi_vif);    // Set virtual interface
spi_cfg.set_en(1'b1);        // Enable DUT
spi_cfg.set_test_mode(1'b1); // Put DUT in test mode
spi_cfg.set_lane_mode(SPI_LANE_16BIT);

// Pass to agent via config_db
uvm_config_db#(spi_agent_config)::set(this, "m_spi_agent", "spi_agent_config", spi_cfg);
```

### 4. Running Sequences

```systemverilog
// WR_CSR command
spi_wr_csr_seq wr_seq = spi_wr_csr_seq::type_id::create("wr_seq");
wr_seq.reg_addr  = 8'h04;
wr_seq.wdata     = 32'h0000_0001;
wr_seq.lane_mode = SPI_LANE_16BIT;
wr_seq.start(sequencer);

// RD_CSR command
spi_rd_csr_seq rd_seq = spi_rd_csr_seq::type_id::create("rd_seq");
rd_seq.reg_addr  = 8'h00;
rd_seq.lane_mode = SPI_LANE_16BIT;
rd_seq.start(sequencer);

// AHB write
spi_ahb_wr32_seq wr32_seq = spi_ahb_wr32_seq::type_id::create("wr32_seq");
wr32_seq.addr      = 32'h0000_1000;
wr32_seq.wdata     = 32'hDEAD_BEEF;
wr32_seq.lane_mode = SPI_LANE_16BIT;
wr32_seq.start(sequencer);

// AHB burst read
spi_ahb_rd_burst_seq burst_seq = spi_ahb_rd_burst_seq::type_id::create("burst_seq");
burst_seq.addr      = 32'h0000_1000;
burst_seq.burst_len = 5'd4;
burst_seq.lane_mode = SPI_LANE_16BIT;
burst_seq.start(sequencer);
```

## Configuration Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| is_active | uvm_active_passive_enum | UVM_ACTIVE | Agent mode |
| has_coverage | bit | 1 | Enable coverage collector |
| has_checks | bit | 1 | Enable protocol checks |
| en | logic | 1'b1 | DUT enable signal |
| test_mode | logic | 1'b1 | DUT test mode signal |
| lane_mode | spi_lane_mode_t | SPI_LANE_16BIT | Default lane mode |
| driving_delay | int unsigned | 0 | Inter-transaction delay |

## Supported Opcodes

| Opcode | Value | Sequence | Description |
|--------|-------|----------|-------------|
| SPI_WR_CSR | 0x10 | spi_wr_csr_seq | CSR register write |
| SPI_RD_CSR | 0x11 | spi_rd_csr_seq | CSR register read |
| SPI_AHB_WR32 | 0x20 | spi_ahb_wr32_seq | AHB single write |
| SPI_AHB_RD32 | 0x21 | spi_ahb_rd32_seq | AHB single read |
| SPI_AHB_WR_BURST | 0x22 | spi_ahb_wr_burst_seq | AHB burst write |
| SPI_AHB_RD_BURST | 0x23 | spi_ahb_rd_burst_seq | AHB burst read |

## Lane Modes

| Mode | Value | Width | Throughput @100MHz |
|------|-------|-------|--------------------|
| SPI_LANE_1BIT | 2'b00 | 1-bit | 12.5 MB/s |
| SPI_LANE_4BIT | 2'b01 | 4-bit | 50 MB/s |
| SPI_LANE_8BIT | 2'b10 | 8-bit | 100 MB/s |
| SPI_LANE_16BIT | 2'b11 | 16-bit | 200 MB/s |

## Status Codes

| Code | Value | Description |
|------|-------|-------------|
| SPI_STS_OK | 0x00 | Success |
| SPI_STS_FRAME_ERR | 0x01 | Frame abort |
| SPI_STS_BAD_OPCODE | 0x02 | Illegal opcode |
| SPI_STS_NOT_IN_TEST | 0x04 | Not in test mode |
| SPI_STS_DISABLED | 0x08 | Module disabled |
| SPI_STS_BAD_REG | 0x10 | Illegal CSR address |
| SPI_STS_ALIGN_ERR | 0x20 | Address alignment error |
| SPI_STS_AHB_ERR | 0x40 | AHB error/timeout |
| SPI_STS_BAD_BURST | 0x80 | Illegal burst length |
| SPI_STS_BURST_BOUND | 0x81 | 1KB boundary crossing |

## Coverage

The coverage collector (`spi_coverage`) tracks:
- Opcode coverage (6 legal opcodes)
- Lane mode coverage (4 modes)
- Status code coverage (10 codes)
- Burst length coverage (legal + illegal)
- Cross coverage: opcode x lane_mode, opcode x status
- CSR address ranges
- AHB address alignment
- FIFO status flags
