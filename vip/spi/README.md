# APLC-Lite SPI VIP

APLC-Lite SPI-like UVM Agent VIP，用于驱动和监控 APLC-Lite 的类 SPI 半双工测试接口。

## 接口信号

| 信号 | 位宽 | 方向 | 说明 |
|------|------|------|------|
| clk | 1 | I | 时钟 |
| rst_n | 1 | I | 异步复位，低有效 |
| pcs_n | 1 | I/O | 帧片选，低有效 |
| pdi[15:0] | 16 | I/O | 并行数据输入 |
| pdo[15:0] | 16 | I | 并行数据输出 |
| pdo_oe | 1 | I | 输出使能 |
| lane_mode[1:0] | 2 | I | 通道模式 |
| en | 1 | I | 模块使能 |
| test_mode | 1 | I | 测试模式 |
| rxfifo_empty | 1 | I | RX FIFO 空 |
| rxfifo_full | 1 | I | RX FIFO 满 |
| txfifo_empty | 1 | I | TX FIFO 空 |
| txfifo_full | 1 | I | TX FIFO 满 |

## 支持的命令

| Opcode | 命令 | 请求帧长 | 响应帧长 |
|--------|------|----------|----------|
| 0x10 | WR_CSR | 48 bit | 8 bit |
| 0x11 | RD_CSR | 16 bit | 40 bit |
| 0x20 | AHB_WR32 | 72 bit | 8 bit |
| 0x21 | AHB_RD32 | 40 bit | 40 bit |
| 0x22 | AHB_WR_BURST | 48+32N bit | 8 bit |
| 0x23 | AHB_RD_BURST | 48 bit | 8+32N bit |

## 配置参数

在 `aplc_spi_agent_config` 中配置：

| 参数 | 默认值 | 说明 |
|------|--------|------|
| is_active | UVM_ACTIVE | Agent 模式 |
| lane_mode | APLC_LANE_16BIT | 通道模式 |
| en_protocol_checks | 1 | 使能协议断言检查 |
| en_x_z_checks | 1 | 使能 X/Z 检查 |

## 编译选项

```makefile
# 需要的编译 include 路径
+incdir+$(VIP_SPI_HOME)

# 编译顺序
$(VIP_SPI_HOME)/aplc_spi_if.sv
$(VIP_SPI_HOME)/aplc_spi_pkg.sv
```

## 使用方法

### 1. 例化接口

```systemverilog
aplc_spi_if u_spi_if(.clk(clk), .rst_n(rst_n));
```

### 2. 配置 agent

```systemverilog
aplc_spi_agent_config spi_cfg = aplc_spi_agent_config::type_id::create("spi_cfg");
spi_cfg.is_active = UVM_ACTIVE;
spi_cfg.lane_mode = APLC_LANE_16BIT;
spi_cfg.m_vif     = u_spi_if;
uvm_config_db#(aplc_spi_agent_config)::set(this, "m_spi_agent*", "cfg", spi_cfg);
```

### 3. 发送命令

```systemverilog
aplc_ahb_wr32_seq wr_seq = aplc_ahb_wr32_seq::type_id::create("wr_seq");
wr_seq.addr  = 32'h1000;
wr_seq.wdata = 32'hDEAD_BEEF;
wr_seq.start(m_sequencer);
```

### 4. 可用序列

| 序列名 | 说明 |
|--------|------|
| aplc_wr_csr_seq | CSR 写 |
| aplc_rd_csr_seq | CSR 读 |
| aplc_ahb_wr32_seq | AHB 单次写 |
| aplc_ahb_rd32_seq | AHB 单次读 |
| aplc_ahb_wr_burst_seq | AHB Burst 写 |
| aplc_ahb_rd_burst_seq | AHB Burst 读 |
| aplc_bad_opcode_seq | 非法 Opcode 测试 |
| aplc_frame_abort_seq | 帧中止测试 |
| aplc_smoke_seq | 冒烟测试序列 |

## SVA 断言

接口中内置以下断言检查：

- pcs_n 信号有效值检查
- pdi 有效帧期间无 X/Z
- pdo 输出期间无 X/Z
- pdo_oe 仅在 pcs_n=0 期间有效
- lane_mode 事务期间稳定
- 复位期间 pdo_oe=0, pdo=0
- 空闲期间 pdi 稳定
- pdo_oe 在 pcs_n 拉高前释放
- 半双工冲突检测

## 通道模式

| lane_mode | 宽度 | 线速 @100MHz |
|-----------|------|-------------|
| APLC_LANE_1BIT | 1-bit | 12.5 MB/s |
| APLC_LANE_4BIT | 4-bit | 50 MB/s |
| APLC_LANE_8BIT | 8-bit | 100 MB/s |
| APLC_LANE_16BIT | 16-bit | 200 MB/s |
