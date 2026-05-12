# APLC SPI VIP 使用说明

## 概述

APLC SPI VIP 是为 APLC-Lite 模块的类 SPI 半双工测试接口开发的 UVM Agent VIP。该 VIP 支持模拟 ATE 主机行为，驱动命令帧并接收响应。

## 支持特性

- 4 种通道模式：1-bit / 4-bit / 8-bit / 16-bit
- 6 种命令 opcode：WR_CSR(0x10)、RD_CSR(0x11)、AHB_WR32(0x20)、AHB_RD32(0x21)、AHB_WR_BURST(0x22)、AHB_RD_BURST(0x23)
- 10 种状态码：OK(0x00)、FRAME_ERR(0x01)、BAD_OPCODE(0x02)、NOT_IN_TEST(0x04)、DISABLED(0x08)、BAD_REG(0x10)、ALIGN_ERR(0x20)、AHB_ERR(0x40)、BAD_BURST(0x80)、BURST_BOUND(0x81)
- AHB Burst：INCR4 / INCR8 / INCR16
- FIFO 状态监控
- SVA 协议断言检查
- 功能覆盖率收集

## 文件结构

```
vip/spi_vip/
├── aplc_spi_pkg.sv          # Package（包含所有文件）
├── aplc_spi_types.sv         # 类型定义（枚举、函数）
├── aplc_spi_if.sv            # 接口（含 SVA 断言）
├── aplc_spi_item.sv          # Sequence Item
├── aplc_spi_mon_item.sv      # Monitor Item
├── aplc_spi_agent_config.sv  # Agent 配置
├── aplc_spi_driver.sv        # Driver（ATE 主机侧）
├── aplc_spi_monitor.sv       # Monitor（观测请求和响应）
├── aplc_spi_sequencer.sv     # Sequencer
├── aplc_spi_coverage.sv      # 功能覆盖率
├── aplc_spi_agent.sv         # Agent
└── aplc_spi_seq_lib.sv       # 序列库
```

## 编译选项

需要在编译时添加以下选项：

```makefile
+incdir+$(VIP_PATH)/spi_vip
-ntb_opts uvm-1.2
```

编译顺序：
1. `aplc_spi_if.sv`（接口定义，需在 package 之前编译）
2. `aplc_spi_pkg.sv`（包文件，内部 include 所有其他文件）

## 配置参数

### aplc_spi_agent_config

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| is_active | uvm_active_passive_enum | UVM_ACTIVE | Agent 模式：ACTIVE 驱动总线，PASSIVE 仅监控 |
| has_coverage | bit | 1 | 是否使能覆盖率收集 |
| has_checks | bit | 1 | 是否使能 SVA 断言检查 |
| default_lane_mode | aplc_lane_mode_e | APLC_LANE_16BIT | 默认通道模式 |
| default_en | bit | 1'b1 | 默认模块使能 |
| default_test_mode | bit | 1'b1 | 默认测试模式 |

### 配置示例

```systemverilog
aplc_spi_agent_config spi_cfg = aplc_spi_agent_config::type_id::create("spi_cfg");
spi_cfg.is_active         = UVM_ACTIVE;
spi_cfg.has_coverage      = 1;
spi_cfg.has_checks        = 1;
spi_cfg.default_lane_mode = APLC_LANE_16BIT;
spi_cfg.default_en        = 1'b1;
spi_cfg.default_test_mode = 1'b1;
spi_cfg.set_vif(spi_if);  // 设置虚接口

uvm_config_db#(aplc_spi_agent_config)::set(null, "uvm_test_top.env.spi_agent", "agent_config", spi_cfg);
```

## 接口连接

### 信号列表

| 接口信号 | 方向 | 位宽 | 说明 |
|----------|------|------|------|
| clk | input | 1 | 时钟（100MHz） |
| rst_n | input | 1 | 异步复位，低有效 |
| en | output | 1 | 模块使能 |
| test_mode | output | 1 | 测试模式使能 |
| pcs_n | output | 1 | 片选，低有效 |
| pdi[15:0] | output | 16 | 并行数据输入 |
| pdo[15:0] | input | 16 | 并行数据输出 |
| pdo_oe | input | 1 | 输出使能 |
| lane_mode[1:0] | output | 2 | 通道模式 |
| rxfifo_empty | input | 1 | RX FIFO 空状态 |
| rxfifo_full | input | 1 | RX FIFO 满状态 |
| txfifo_empty | input | 1 | TX FIFO 空状态 |
| txfifo_full | input | 1 | TX FIFO 满状态 |

### 连接示例

```systemverilog
aplc_spi_if spi_if (.clk(clk), .rst_n(rst_n));

assign pcs_n     = spi_if.pcs_n;
assign pdi       = spi_if.pdi;
assign en        = spi_if.en;
assign test_mode = spi_if.test_mode;
assign lane_mode = spi_if.lane_mode;
assign spi_if.pdo           = pdo;
assign spi_if.pdo_oe       = pdo_oe;
assign spi_if.rxfifo_empty = rxfifo_empty;
assign spi_if.rxfifo_full  = rxfifo_full;
assign spi_if.txfifo_empty = txfifo_empty;
assign spi_if.txfifo_full  = txfifo_full;
```

## SVA 断言

VIP 接口中内置以下 SVA 断言，可通过接口开关独立控制：

| 断言组 | 开关 | 检查内容 |
|--------|------|----------|
| 复位检查 | en_reset_checks | 复位后 pdo_oe=0、FIFO 空 |
| X/Z 检查 | en_x_z_checks | 关键信号非 X/Z |
| 协议检查 | en_protocol_checks | lane_mode 稳定性、帧协议、turnaround、FIFO 互斥 |

## 序列库

### 基本序列

| 序列名 | 说明 |
|--------|------|
| aplc_spi_wr_csr_seq | CSR 写序列 |
| aplc_spi_rd_csr_seq | CSR 读序列 |
| aplc_spi_ahb_wr32_seq | AHB 单次写序列 |
| aplc_spi_ahb_rd32_seq | AHB 单次读序列 |
| aplc_spi_ahb_wr_burst_seq | AHB Burst 写序列 |
| aplc_spi_ahb_rd_burst_seq | AHB Burst 读序列 |

### 错误注入序列

| 序列名 | 说明 |
|--------|------|
| aplc_spi_bad_opcode_seq | 非法 opcode 注入 |
| aplc_spi_disabled_seq | 模块未使能（en=0） |
| aplc_spi_not_in_test_seq | 非测试模式（test_mode=0） |
| aplc_spi_bad_reg_seq | 非法 CSR 地址注入 |
| aplc_spi_align_err_seq | 地址非对齐注入 |
| aplc_spi_bad_burst_seq | 非法 burst_len 注入 |
| aplc_spi_burst_bound_seq | Burst 跨 1KB 边界注入 |

### 随机序列

| 序列名 | 说明 |
|--------|------|
| aplc_spi_rand_multi_cmd_seq | 随机多命令序列 |
| aplc_spi_full_cross_seq | 全交叉覆盖序列 |

### 使用基类序列辅助方法

`aplc_spi_base_seq` 提供以下便捷方法：

```systemverilog
// CSR 读写
send_wr_csr(reg_addr, wdata, lane_mode);
send_rd_csr(reg_addr, rdata, status, lane_mode);

// AHB 单次读写
send_ahb_wr32(addr, wdata, status, lane_mode);
send_ahb_rd32(addr, rdata, status, lane_mode);

// AHB Burst 读写
send_ahb_wr_burst(addr, burst_len, wdata_q, status, lane_mode);
send_ahb_rd_burst(addr, burst_len, rdata_q, status, lane_mode);
```

## 覆盖率

VIP 自动收集以下功能覆盖率：

- opcode 覆盖（6 种命令类型）
- lane_mode 覆盖（4 种通道模式）
- status 覆盖（10 种状态码）
- burst_len 覆盖（1/4/8/16）
- opcode x lane_mode 交叉覆盖
- opcode x status 交叉覆盖
- FIFO 状态覆盖
