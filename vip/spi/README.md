# APLC SPI VIP 使用说明

## 概述

APLC SPI VIP 是一个 UVM agent，用于验证 APLC-Lite 模块的 SPI-like 测试接口协议。VIP 支持 1/4/8/16-bit 四种 lane 模式，6 种命令类型，以及错误注入功能。

## 文件结构

```
vip/spi/
├── aplc_spi_pkg.sv          # Package 文件
├── aplc_spi_if.sv           # SystemVerilog 接口（含 SVA 断言）
├── aplc_spi_types.sv        # 类型定义（枚举、typedef）
├── aplc_spi_item.sv         # Transaction item
├── aplc_spi_mon_item.sv     # Monitor item（含时间戳和协议异常标志）
├── aplc_spi_agent_config.sv # Agent 配置
├── aplc_spi_coverage.sv     # 功能覆盖率收集
├── aplc_spi_monitor.sv      # Monitor（UVM_LOW 打印 transaction）
├── aplc_spi_driver.sv       # Driver（等待复位后驱动）
├── aplc_spi_sequencer.sv    # Sequencer
├── aplc_spi_agent.sv        # Agent
└── aplc_spi_seq_lib.sv      # 序列库
```

## 编译选项

- 需要添加 `+incdir+$VIP_HOME/vip/spi` 到编译命令
- 编译顺序：先编译 `aplc_spi_if.sv`（通过 pkg 中的 `include 处理），再编译 `aplc_spi_pkg.sv`
- 需要 UVM 1.2 支持：`-ntb_opts uvm-1.2`

## 配置参数

### aplc_spi_agent_config

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| is_active | uvm_active_passive_enum | UVM_ACTIVE | Agent 模式 |
| has_coverage | bit | 1'b1 | 是否收集覆盖率 |
| has_checks | bit | 1'b1 | 是否使能 SVA 断言 |

### 设置方法

```systemverilog
aplc_spi_agent_config cfg = aplc_spi_agent_config::type_id::create("cfg");
cfg.is_active = UVM_ACTIVE;
cfg.set_vif(spi_vif);
uvm_config_db #(aplc_spi_agent_config)::set(this, "m_agent", "aplc_spi_agent_config", cfg);
```

## 接口信号

| 信号 | 方向 | 位宽 | 说明 |
|------|------|------|------|
| clk | input | 1 | 时钟 |
| rst_n | input | 1 | 异步复位，低有效 |
| en | input | 1 | 模块使能 |
| test_mode | input | 1 | 测试模式指示 |
| pcs_n | I/O | 1 | 片选，低有效，定义帧边界 |
| pdi | I/O | 16 | 并行数据输入（ATE -> DUT） |
| pdo | input | 16 | 并行数据输出（DUT -> ATE） |
| pdo_oe | input | 1 | 输出使能 |
| lane_mode | input | 2 | 通道模式选择 |
| rxfifo_empty | input | 1 | RX FIFO 空标志 |
| rxfifo_full | input | 1 | RX FIFO 满标志 |
| txfifo_empty | input | 1 | TX FIFO 空标志 |
| txfifo_full | input | 1 | TX FIFO 满标志 |

## SVA 断言清单

| 断言标签 | 对应 Checker | 说明 |
|----------|-------------|------|
| APLC_SPI_PDO_OE_AFTER_RESET_ERR | CHK_001 | 复位后 pdo_oe 为 0 |
| APLC_SPI_PDO_ZERO_AFTER_RESET_ERR | CHK_001 | 复位后 pdo 为 0 |
| APLC_SPI_LANE_MODE_STABLE_ERR | CHK_005/010 | 事务期间 lane_mode 稳定 |
| APLC_SPI_PDO_OE_IDLE_ERR | CHK_006 | 空闲时 pdo_oe 为 0 |
| APLC_SPI_PCS_N_FALL_PDO_OE_ERR | CHK_006 | 帧开始时 pdo_oe 为 0 |
| APLC_SPI_PCS_N_XZ_ERR | - | pcs_n 无 X/Z |
| APLC_SPI_LANE_MODE_XZ_ERR | - | lane_mode 无 X/Z |
| APLC_SPI_PDO_OE_XZ_ERR | - | pdo_oe 无 X/Z |
| APLC_SPI_PDO_XZ_ERR | - | 响应期间 pdo 无 X/Z |
| APLC_SPI_RXFIFO_STATUS_XZ_ERR | - | rxfifo 状态无 X/Z |
| APLC_SPI_TXFIFO_STATUS_XZ_ERR | - | txfifo 状态无 X/Z |
| APLC_SPI_RXFIFO_MUTEX_ERR | - | rxfifo 不能同时空和满 |
| APLC_SPI_TXFIFO_MUTEX_ERR | - | txfifo 不能同时空和满 |

## 序列库

| 序列名 | 说明 | 支持的测试用例 |
|--------|------|---------------|
| aplc_spi_wr_csr_seq | CSR 写操作 | TC_004, TC_006, TC_008-013 |
| aplc_spi_rd_csr_seq | CSR 读操作 | TC_004, TC_014, TC_024 |
| aplc_spi_ahb_wr32_seq | AHB 单次写 | TC_015, TC_021 |
| aplc_spi_ahb_rd32_seq | AHB 单次读 | TC_016, TC_021 |
| aplc_spi_ahb_wr_burst_seq | AHB Burst 写 | TC_019, TC_021, TC_029 |
| aplc_spi_ahb_rd_burst_seq | AHB Burst 读 | TC_017, TC_018, TC_021, TC_029 |
| aplc_spi_bad_opcode_seq | 非法 opcode 注入 | TC_020, TC_031 |
| aplc_spi_bad_reg_seq | 非法 CSR 地址注入 | TC_005, TC_031 |
| aplc_spi_align_err_seq | 非对齐地址注入 | TC_031 |
| aplc_spi_bad_burst_len_seq | 非法 burst_len 注入 | TC_031 |
| aplc_spi_not_in_test_seq | test_mode=0 场景 | TC_007 |
| aplc_spi_random_seq | 随机命令序列 | TC_029, TC_030, TC_032 |

## Monitor 打印格式

Monitor 在每个 transaction 完成后以 UVM_LOW 级别打印：

```
[MON] Collected item: opcode:APLC_SPI_AHB_WR32 reg_addr:0x00 addr:0x10000000 burst_len:0 lane_mode:3 wdata[1]:0xdeadbeef  status:0x00 [1050..1200]
```

协议异常追加标志：
- `FRAME_ABORT` - 帧中止（pcs_n 提前释放）
- `LANE_CHANGED` - 事务期间 lane_mode 变化
- `TA_ERR` - Turnaround 错误

## 覆盖率

VIP 收集以下功能覆盖率：
- opcode 覆盖（6 种命令类型）
- lane_mode 覆盖（1/4/8/16-bit）
- status 覆盖（10 种状态码）
- burst_len 覆盖（1/4/8/16）
- opcode × lane_mode 交叉覆盖
- FIFO 状态覆盖（empty/full）

## 运行冒烟测试

```bash
cd tbus
make sim TEST=aplc_smoke_test
```
