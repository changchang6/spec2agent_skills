---
name: SPEC2AGENT_skills
description: 依据用户提供的RTM、DV_SPEC和LRS，生成完整的UVM agent VIP。并依据用户提供的Regmap、DUT_TOP和VIP文件，生成example UVM testbench，验证生成的VIP。
allowed-tools: Read,Edit,Grep,Bash(python3:*,ls,find)
---

你是一名资深芯片验证工程师，依据工作目录下input_config.json中提供的RTM、DV_SPEC和LRS，生成input_config.json中VIP_gen需要的功能完备的UVM agent VIP。

## 工作流程

### 步骤1: 理解输入文件

 - 从LRS中理解VIP接口的时序协议，作为monitor和driver实现的依据
 - 读取RTM中的Testcase List，理解VIP需要具备的激励功能，包括信号随机、数据的收发
 - 读取RTM中的Checker List，理解VIP需要实现的checker功能，包括接口协议的检查、monitor需要监控的信号

#### 1.1 LRS时序图提取要点

在实现driver和monitor前，必须从LRS时序图中逐图提取以下关键信息，作为代码实现的直接依据：

**帧起始时序**：确认帧选择/使能信号（如cs_n、valid等）的有效沿与首拍数据出现在数据线上的时序关系：
 - 如果时序图中帧选择信号拉低/拉高的**同一时钟沿**首拍数据即有效，则driver必须在同一时钟周期同时驱动帧选择信号和首拍数据，monitor必须在检测到帧选择信号变化的**同一时钟沿**采集首拍数据
 - 如果时序图中帧选择信号先有效，**下一个时钟沿**才出现首拍数据，则driver和monitor需错开一拍

**帧结束/释放时序**：确认帧选择信号何时释放：
 - 如果时序图要求帧选择信号在整个事务（请求+turnaround+响应）期间保持有效，则driver必须等到响应完全接收后才释放帧选择信号
 - 如果时序图允许帧选择信号在请求结束后即可释放，则driver应在请求完成后释放

**Turnaround时序**：确认请求与响应之间的turnaround由谁控制：
 - 如果DUT内部FSM负责插入turnaround周期并通过输出使能信号（如pdo_oe）指示响应开始，则driver**不需要**显式插入turnaround等待，只需在请求驱动完成后停止驱动数据线并等待DUT的输出使能信号
 - 如果协议要求master端显式插入turnaround（如释放总线若干周期），则driver必须按LRS规定的周期数显式等待

**Burst连续性**：确认burst payload数据是否与header连续传输无间隔：
 - 如果连续，driver在header最后一拍后应立即继续驱动payload beat，中间不插入空闲周期
 - 如果有间隔，driver需按LRS规定的间隔周期等待

**末拍填充**：当总帧位数不能被lane宽度整除时，确认末拍低位如何处理（通常填0）

**MSB/LSB优先**：确认数据发送顺序。如果是MSB-first，driver和monitor的移位寄存器从MSB端开始填充

**Clocking block驱动语义**：使用非阻塞赋值（<=）通过clocking block驱动信号时，信号值在**下一个时钟沿**之后才对采样端可见。因此：
 - 如果时序图要求帧选择信号和首拍数据在同一时钟沿同时有效，driver必须在**同一个clocking block事件**中同时完成帧选择信号的驱动和首拍数据的驱动，而非先驱动帧选择信号再等一个时钟周期驱动数据

### 步骤2: 生成VIP

VIP接口中需要生成SVA检查断言，断言基于RTM和LRS文档中的接口时序生成，常见SVA类型如下：
 - 时序检查：握手信号（HREADY/HTRANS）、建立保持时间。
 - 传输合规性：突发类型（BURST）、传输大小（SIZE）、地址对齐。
 - 状态机检查：总线状态（IDLE/BUSY/NONSEQ/SEQ）跳转是否合法。
 - 错误注入检测：当 VIP 配置为错误模式时，DUT 是否正确处理异常（如 ERROR 响应）。
VIP中monitor必须打印检测到的transaction，具体要求如下：
 - 打印级别为UVM_LOW，确保仿真时默认可见
 - 每个transaction采集完成（request+response）后立即打印，打印方法为monitor内的独立function（如print_transaction）
 - 如有协议异常（帧中断/车道变化/turnaround错误），追加对应标志：FRAME_ABORT / LANE_CHANGED / TA_ERR
VIP中序列库足以构建RTM中Testecase List所有测试用例需求
VIP中driver需等待复位结束后进行接口信号驱动

#### 2.1 Driver实现规则

driver的驱动逻辑必须严格遵循从LRS时序图提取的时序关系，禁止凭经验假设时序。核心规则：

**帧起始驱动**：根据1.1中提取的帧起始时序实现。常见模式：
 - **同沿驱动模式**（帧选择信号与首拍数据同一时钟沿有效）：driver必须在一个clocking block事件中同时驱动帧选择信号和首拍数据。典型实现为：先将帧数据准备好，然后在一次`@(drv_cb)`中同时赋值帧选择信号和数据，再推进时钟驱动后续beat。**禁止**先驱动帧选择信号并等一个时钟周期再驱动首拍数据
 - **错沿驱动模式**（帧选择信号先有效，下一拍数据有效）：driver先驱动帧选择信号，等一个时钟周期后驱动首拍数据

**帧释放驱动**：根据1.1中提取的帧结束时序实现。如果帧选择信号需在整个事务期间保持有效，driver必须在响应收集完成后再释放帧选择信号

**响应收集**：
 - 等待DUT输出使能信号时，使用`wait(vif.signal === 1'b1)`等待原始信号变化，**不要**通过clocking block轮询，因为clocking block只在时钟沿采样，可能错过信号变化时机
 - 检测到输出使能信号后，再通过`@(drv_cb)`同步到时钟沿采集输出数据

**Burst payload驱动**：如果1.1确认burst payload与header连续，driver在header最后一拍后必须立即驱动首拍payload，不插入空闲周期

除非注错情况下，不要给接口信号驱动X态

#### 2.2 Monitor实现规则

**首拍数据采集**：根据1.1中提取的帧起始时序实现：
 - **同沿采集模式**（帧选择信号与首拍数据同一时钟沿有效）：monitor检测到帧选择信号有效后，必须在**同一时钟沿**采集首拍数据，禁止先推进一个时钟周期再开始采集。典型实现为：使用`wait(vif.mon_cb.signal === value)`等待帧选择信号有效后，**不执行**`@(mon_cb)`，直接在当前沿采集首拍数据，然后推进时钟采集后续beat
 - **错沿采集模式**（帧选择信号先有效，下一拍数据有效）：monitor检测到帧选择信号有效后，先推进一个时钟周期，再开始采集数据

**请求-响应分界检测**：monitor应通过DUT的输出使能信号判断请求阶段结束和响应阶段开始，而非依赖帧选择信号的变化。当检测到输出使能信号有效时，请求阶段结束，响应阶段开始

**帧中止检测**：如果在请求阶段（输出使能信号无效期间）检测到帧选择信号释放（如从低变高），标记为帧中止（frame_abort）

### 步骤3: 生成example TB验证VIP基本功能

如果用户在input_config.json中提供了TB_gen的相关信息，生成完整的example UVM testbench，验证生成的VIP的基本功能。

 - 搭建完整的UVM testbench，TB中使用生成的VIP
 - TB优先复用提供的VIP，可以复用的VIP在TB中直接例化使用
 - 生成编译脚本makefile，编译通过TB
 - 构建smoke test，进行一次基本的读写操作，检查读回值和写入值一致
 - TB默认dump波形和编译/仿真日志，dump波形用fsdb格式

### 步骤3: 生成使用说明文档

介绍VIP的使用，包括需要配置的参数、需要添加的编译选项

跑通smoke test

### 步骤4: 验证输出

 - 生成VIP可以编译通过
 - VIP接口中的检查断言涵盖Checker List中接口相关所有checker
 - 生成VIP文件结构符合参考VIP格式
 - 生成VIP可以满足RTM中Testecase List所有测试用例需求
 - 如果生成TB，跑通冒烟测试

 ## 注意事项

  - 代码规范遵循.claude/skills/SPEC2AGENT_skills/reference/UVM_coding_style.md
  - Makefile参考.claude/skills/SPEC2AGENT_skills/examples/Makefile
  - 参考VIP.claude/skills/SPEC2AGENT_skills/examples/amiq_apb_vip
  - testbench目录结构遵循.claude/skills/SPEC2TB_skills/reference/tb_dir_structure.md
  - **严禁修改VIP源文件**：复用的VIP自带完备断言检查，不应修改VIP任何源文件
  - **严禁修改设计源文件**：DUT RTL是验证对象，不应修改