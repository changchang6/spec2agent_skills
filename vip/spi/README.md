# APLC SPI VIP 使用说明

## 概述

APLC SPI VIP 是一个 UVM agent，用于验证 APLC-Lite 模块的类 SPI 半双工测试接口。VIP 作为 ATE 主机驱动请求帧并收集响应。

## 文件结构

```
vip/spi/src/
├── aplc_spi_if.sv          # 接口定义（含SVA断言）
├── aplc_spi_pkg.sv         # 包定义
├── aplc_spi_defines.sv     # 宏定义
├── aplc_spi_types.sv       # 类型定义和时序常量
├── aplc_spi_item.sv        # 事务项（驱动端）
├── aplc_spi_mon_item.sv    # 监控事务项
├── aplc_spi_agent_config.sv # Agent配置
├── aplc_spi_coverage.sv    # 覆盖率收集
├── aplc_spi_monitor.sv     # 监控器
├── aplc_spi_sequencer.sv   # 序列器
├── aplc_spi_driver.sv      # 驱动器
├── aplc_spi_agent.sv       # Agent
└── aplc_spi_seq_lib.sv     # 序列库
```

## 配置参数

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| m_is_active | uvm_active_passive_enum | UVM_ACTIVE | Agent模式 |
| lane_mode | aplc_lane_mode_e | APLC_LANE_16BIT | 默认lane模式 |
| en | bit | 1'b1 | 模块使能 |
| test_mode | bit | 1'b1 | 测试模式使能 |
| inject_bad_opcode | bit | 1'b0 | 注入非法opcode |
| inject_frame_abort | bit | 1'b0 | 注入帧中止 |
| inject_lane_change | bit | 1'b0 | 注入lane切换 |

## 编译选项

```makefile
+incdir+$(VIP_HOME)/src
$(VIP_HOME)/src/aplc_spi_if.sv
$(VIP_HOME)/src/aplc_spi_pkg.sv
-ntb_opts uvm-1.2
-sverilog
```

## 使用示例

### 在TB中例化

```systemverilog
// 1. 声明接口
aplc_spi_if spi_if(.clk(clk), .rst_n(rst_n));

// 2. 配置agent
aplc_spi_agent_config spi_cfg = aplc_spi_agent_config::type_id::create("spi_cfg");
spi_cfg.m_vif = spi_if;
spi_cfg.lane_mode = APLC_LANE_16BIT;

// 3. 通过config_db传递
uvm_config_db#(virtual aplc_spi_if)::set(null, "uvm_test_top.m_env.m_spi_agent*", "vif", spi_if);
uvm_config_db#(aplc_spi_agent_config)::set(null, "uvm_test_top.m_env.m_spi_agent*", "m_config", spi_cfg);
```

### 发送命令

```systemverilog
// WR_CSR
aplc_spi_item txn = aplc_spi_item::type_id::create("txn");
txn.opcode   = APLC_OP_WR_CSR;
txn.reg_addr = 8'h04;
txn.wdata    = new[1];
txn.wdata[0] = 32'h00000001;
txn.lane_mode = APLC_LANE_16BIT;
start_item(txn);
finish_item(txn);
// 检查 txn.status

// AHB_RD_BURST x4
txn = aplc_spi_item::type_id::create("txn");
txn.opcode    = APLC_OP_AHB_RD_BURST;
txn.addr      = 32'h10000000;
txn.burst_len = 5'd4;
txn.lane_mode = APLC_LANE_16BIT;
start_item(txn);
finish_item(txn);
// 检查 txn.status 和 txn.rdata[]
```

## 支持的序列

| 序列名 | 功能 | 对应TC |
|--------|------|--------|
| aplc_spi_wr_csr_seq | CSR写 | TC_012 |
| aplc_spi_rd_csr_seq | CSR读 | TC_014 |
| aplc_spi_ahb_wr32_seq | AHB单次写 | TC_015 |
| aplc_spi_ahb_rd32_seq | AHB单次读 | TC_016 |
| aplc_spi_ahb_wr_burst_seq | AHB Burst写 | TC_019 |
| aplc_spi_ahb_rd_burst_seq | AHB Burst读 | TC_017/18 |
| aplc_spi_bad_opcode_seq | 非法opcode | TC_020 |
| aplc_spi_frame_abort_seq | 帧中止 | TC_025 |
| aplc_spi_align_err_seq | 地址未对齐 | TC_039 |
| aplc_spi_bad_burst_seq | 非法burst_len | TC_035 |
| aplc_spi_burst_bound_seq | Burst跨1KB边界 | TC_044 |
| aplc_spi_lane_switch_seq | Lane模式切换 | TC_022/23 |
| aplc_spi_csr_access_seq | CSR全寄存器访问 | TC_004 |
| aplc_spi_all_opcode_seq | 全opcode遍历 | TC_021 |

## LRS时序常量（已编码在driver/monitor中）

| 常量 | 值 | 说明 |
|------|----|------|
| FRAME_START_OFFSET_EDGE | 1 | 错沿模式：pcs_n先拉低，下一拍数据有效 |
| FRAME_END_AFTER_RESPONSE | 1 | 响应后释放pcs_n |
| TA_BY_DUT | 1 | DUT控制turnaround |
| BURST_CONTINUOUS | 1 | Burst beat连续传输 |
| HAS_RXFIFO_FULL | 1 | 存在RXFIFO满反压 |
| HAS_TXFIFO_EMPTY | 1 | 存在TXFIFO空暂停 |

## SVA断言覆盖

| 断言 | 对应Checker | 说明 |
|------|------------|------|
| p_reset_pdo_oe | CHK_001 | 复位后pdo_oe=0 |
| p_lane_mode_stable_during_txn | CHK_005/010 | 事务期间lane_mode稳定 |
| p_pdo_oe_idle | CHK_006 | 空闲态pdo_oe=0 |
