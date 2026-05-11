# SPI VIP 使用说明文档

## 1. VIP 概述

SPI VIP 是用于验证 APLC-Lite 模块外部测试接口的 UVM VIP。该 VIP 支持以下特性：

- 支持四种 lane mode：1-bit、4-bit、8-bit、16-bit
- 支持六种命令类型：
  - WR_CSR (0x10): CSR 寄存器写
  - RD_CSR (0x11): CSR 寄存器读
  - AHB_WR32 (0x20): AHB 单次写
  - AHB_RD32 (0x21): AHB 单次读
  - AHB_WR_BURST (0x22): AHB Burst 写
  - AHB_RD_BURST (0x23): AHB Burst 读
- 支持协议检查和覆盖率收集
- 完全符合 UVM 1.2 规范

## 2. 文件结构

```
vip/spi_vip/
├── spi_if.sv           # 接口定义
├── spi_types.sv        # 类型定义
├── spi_item.sv         # 事务项
├── spi_agent_config.sv # Agent 配置类
├── spi_driver.sv       # Driver
├── spi_monitor.sv      # Monitor
├── spi_sequencer.sv    # Sequencer
├── spi_coverage.sv     # Coverage
├── spi_agent.sv        # Agent
├── spi_seq_lib.sv      # 序列库
├── spi_pkg.sv          # Package
├── Makefile            # 编译脚本
└── README.md           # 使用说明
```

## 3. 编译方法

### 3.1 使用 VCS 编译

```bash
cd vip/spi_vip
make comp
```

### 3.2 编译选项

可以在 Makefile 中修改以下参数：
- `VCS`: VCS 编译器路径
- `VCS_COMP_OPTS`: 编译选项

## 4. 集成到测试平台

### 4.1 接口实例化

在顶层模块中实例化 SPI 接口：

```systemverilog
module tb_top;
    logic clk;
    logic rst_n;

    // 生成时钟
    initial clk = 0;
    forever #5 clk = ~clk;

    // 实例化 SPI 接口
    spi_if spi_intf(clk);

    // 连接 DUT
    aplc_lite dut (
        .clk_i(clk),
        .rst_n_i(rst_n),
        .pcs_n_i(spi_intf.pcs_n),
        .pdi_i(spi_intf.pdi),
        .pdo_o(spi_intf.pdo),
        .pdo_oe_o(spi_intf.pdo_oe),
        .lane_mode_i(spi_intf.lane_mode),
        .en_i(spi_intf.en),
        .test_mode_i(spi_intf.test_mode)
    );

    // 设置 reset
    initial begin
        rst_n = 0;
        #100 rst_n = 1;
    end
endmodule
```

### 4.2 Agent 配置

在测试中配置 Agent：

```systemverilog
class my_test extends uvm_test;
    spi_agent m_spi_agent;
    spi_agent_config m_spi_config;

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        m_spi_config = spi_agent_config::type_id::create("m_spi_config");
        m_spi_config.set_is_active(UVM_ACTIVE);
        m_spi_config.set_has_coverage(1);

        uvm_config_db#(spi_agent_config)::set(this, "m_spi_agent", "agent_config", m_spi_config);

        if(!uvm_config_db#(spi_vif_t)::get(this, "", "spi_vif", m_spi_config)) begin
            `uvm_fatal("TEST", "SPI interface not found")
        end

        m_spi_agent = spi_agent::type_id::create("m_spi_agent", this);
    endfunction
endclass
```

### 4.3 设置虚拟接口

在顶层设置虚拟接口：

```systemverilog
initial begin
    uvm_config_db#(spi_vif_t)::set(null, "uvm_test_top", "spi_vif", tb_top.spi_intf);
    run_test("my_test");
end
```

## 5. 使用序列

### 5.1 CSR 写序列

```systemverilog
spi_wr_csr_seq wr_csr;
wr_csr = spi_wr_csr_seq::type_id::create("wr_csr");
wr_csr.addr = 8'h04;  // CTRL 寄存器地址
wr_csr.data = 32'h00000001;
wr_csr.lane_mode = LANE_MODE_16BIT;
wr_csr.start(m_spi_agent.m_sequencer);
```

### 5.2 CSR 读序列

```systemverilog
spi_rd_csr_seq rd_csr;
rd_csr = spi_rd_csr_seq::type_id::create("rd_csr");
rd_csr.addr = 8'h00;  // VERSION 寄存器地址
rd_csr.lane_mode = LANE_MODE_16BIT;
rd_csr.start(m_spi_agent.m_sequencer);

// 检查返回值
if(rd_csr.status == STS_OK) begin
    `uvm_info("TEST", $sformatf("Read data: 0x%08h", rd_csr.rdata), UVM_LOW)
end
```

### 5.3 AHB 单次写序列

```systemverilog
spi_ahb_wr32_seq wr32;
wr32 = spi_ahb_wr32_seq::type_id::create("wr32");
wr32.randomize() with {
    addr == 32'h10000000;
    data == 32'hDEADBEEF;
    lane_mode == LANE_MODE_16BIT;
};
wr32.start(m_spi_agent.m_sequencer);
```

### 5.4 AHB Burst 写序列

```systemverilog
spi_ahb_wr_burst_seq wr_burst;
wr_burst = spi_ahb_wr_burst_seq::type_id::create("wr_burst");
wr_burst.randomize() with {
    addr == 32'h20000000;
    burst_len == 4;
    lane_mode == LANE_MODE_16BIT;
    wdata_queue.size() == 4;
};
wr_burst.start(m_spi_agent.m_sequencer);
```

### 5.5 使用所有操作的混合序列

```systemverilog
spi_all_ops_seq all_ops;
all_ops = spi_all_ops_seq::type_id::create("all_ops");
all_ops.num_iterations = 100;
all_ops.start(m_spi_agent.m_sequencer);
```

## 6. Lane Mode 配置

VIP 支持四种 lane mode，对应不同的吞吐量：

| Lane Mode | lane_mode_i | 每拍传输位数 | 原始线速 @100MHz |
|-----------|-------------|--------------|------------------|
| 1-bit     | 2'b00       | 1 bit        | 12.5 MB/s        |
| 4-bit     | 2'b01       | 4 bits       | 50 MB/s          |
| 8-bit     | 2'b10       | 8 bits       | 100 MB/s         |
| 16-bit    | 2'b11       | 16 bits      | 200 MB/s         |

使用约束：

```systemverilog
trans.randomize() with {
    lane_mode == LANE_MODE_16BIT;  // 最高吞吐量
};
```

## 7. 状态码

VIP 支持以下状态码检查：

| 状态码        | 值     | 含义                    |
|---------------|--------|-------------------------|
| STS_OK        | 0x00   | 成功                    |
| STS_FRAME_ERR | 0x01   | 帧错误                  |
| STS_BAD_OPCODE| 0x02   | 非法 Opcode             |
| STS_NOT_IN_TEST| 0x04  | 非测试模式              |
| STS_DISABLED  | 0x08   | 模块未使能              |
| STS_BAD_REG   | 0x10   | 非法 CSR 地址           |
| STS_ALIGN_ERR | 0x20   | 地址未对齐              |
| STS_AHB_ERR   | 0x40   | AHB 总线错误            |
| STS_BAD_BURST | 0x80   | 非法 burst_len          |
| STS_BURST_BOUND| 0x81  | Burst 跨 1KB 边界       |

## 8. 覆盖率

VIP 收集以下覆盖率：

- Opcode 类型覆盖率
- Lane mode 覆盖率
- 读写方向覆盖率
- 响应状态覆盖率
- Burst 长度覆盖率
- 地址对齐覆盖率
- Opcode 与 Lane mode 交叉覆盖率
- Opcode 与状态交叉覆盖率

## 9. 协议检查

VIP 接口中包含以下协议检查：

- pcs_n 信号 X/Z 检查
- pdi 信号 X/Z 检查
- lane_mode 事务期间稳定性检查
- pdo_oe 有效时 pcs_n 必须为低检查

可通过配置类开关这些检查：

```systemverilog
m_spi_config.set_en_protocol_checks(1);  // 启用协议检查
m_spi_config.set_en_x_z_checks(1);       // 启用 X/Z 检查
```

## 10. 注意事项

1. **Lane Mode 约束**：事务执行期间（pcs_n=0）lane_mode 必须保持稳定，否则会导致帧数据损坏。

2. **地址对齐**：AHB 命令地址必须 4-byte 对齐（addr[1:0]==2'b00）。

3. **Burst 边界**：Burst 地址不得跨 1KB 边界。

4. **Burst 长度**：仅支持 burst_len = {1, 4, 8, 16}。

5. **测试模式**：test_mode_i 必须为 1，否则所有命令返回 STS_NOT_IN_TEST。

6. **模块使能**：en_i 必须为 1，否则所有命令返回 STS_DISABLED。

## 11. 参考文档

- APLC LRS v2.2 - APLC-Lite 逻辑规格说明书
- UVM 1.2 Class Reference
- AMBA AHB-Lite Protocol Specification