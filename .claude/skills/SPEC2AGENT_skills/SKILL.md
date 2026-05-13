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

在实现driver和monitor前，必须从LRS时序图中逐图提取以下关键信息，作为代码实现的直接依据。提取结果必须以常量或参数形式定义在代码开头（如localparam或枚举），禁止将时序假定硬编码散落在驱动逻辑中。

**帧起始时序**：确认帧选择/使能信号的有效沿与首拍数据出现在数据线上的时序关系。提取后必须写为枚举常量（如`FRAME_START_OFFSET_EDGE`/`FRAME_START_SAME_EDGE`）：
 - **错沿模式**（offset-edge，更常见）：时序图中帧选择信号先有效，**下一个时钟沿**首拍数据才有效。driver先驱动帧选择信号，等一个时钟周期后再驱动首拍数据；monitor检测到帧选择信号有效后，推进一个时钟周期再开始采集数据
 - **同沿模式**（same-edge，较少见）：时序图中帧选择信号与首拍数据在**同一时钟沿**同时有效。driver必须在同一个clocking block事件中同时驱动帧选择信号和首拍数据；monitor必须在检测到帧选择信号的**同一时钟沿**采集首拍数据

**帧结束/释放时序**：确认帧选择信号何时释放。提取后写为枚举常量（如`FRAME_END_AFTER_RESPONSE`/`FRAME_END_AFTER_REQUEST`）：
 - **响应后释放**（更常见）：帧选择信号在整个事务（请求+turnaround+响应）期间保持有效，driver必须等到DUT输出使能信号降下后再释放帧选择信号
 - **请求后释放**：帧选择信号在请求完成后即可释放，driver在请求驱动完成后释放

**Turnaround时序**：确认请求与响应之间的turnaround由谁控制。提取后写为枚举常量（如`TA_BY_DUT`/`TA_BY_MASTER`）：
 - **DUT控制**（更常见）：DUT内部FSM负责插入turnaround周期并通过输出使能信号指示响应开始，driver**不需要**显式插入turnaround等待，只需在请求驱动完成后停止驱动数据线并等待DUT的输出使能信号
 - **Master控制**：协议要求master端显式插入turnaround（如释放总线若干周期），driver必须按LRS规定的周期数显式等待

**Burst连续性**：确认burst payload数据是否与header连续传输无间隔。提取后写为布尔常量：
 - 如果连续，driver在header最后一拍后应立即继续驱动payload beat，中间不插入空闲周期
 - 如果有间隔，driver需按LRS规定的间隔周期等待

**FIFO反压**：确认接口是否包含FIFO状态信号以及协议对反压的规定：
 - 如果存在接收FIFO满信号，driver在驱动数据前**必须检查**该信号：满时停止驱动数据线，非满时恢复驱动。违反此规则会导致数据丢失且DUT无法检测
 - 如果存在发送FIFO空信号，driver/monitor在收集响应时**必须处理暂停**：输出使能有效但FIFO为空时，输出数据保持上一拍值，应跳过该拍不采集新数据，等待FIFO非空后恢复

**末拍填充**：当总帧位数不能被数据位宽整除时，确认末拍低位如何处理（通常填0）

**MSB/LSB优先**：确认数据发送顺序。如果是MSB-first，driver和monitor的移位寄存器从MSB端开始填充

**Clocking block驱动语义**：使用非阻塞赋值（<=）通过clocking block驱动信号时，信号值在**下一个时钟沿**之后才对采样端可见：
 - 错沿模式下：driver在某拍驱动帧选择信号（如`drv_cb.frame_sel <= 0`），下一个`@(drv_cb)`后驱动首拍数据——这正好符合LRS中"帧选择信号先有效，下一拍数据有效"的要求，是错沿模式的自然实现
 - 同沿模式下：driver必须在**同一个clocking block事件**中同时完成帧选择信号的驱动和首拍数据的驱动

### 步骤2: 生成VIP

VIP中序列库足以构建RTM中Testecase List所有测试用例需求

#### 2.1 Interface实现规则

VIP接口中需要生成SVA检查断言，断言基于RTM和LRS文档中的接口时序生成，常见SVA类型如下：
 - 时序检查：握手信号（HREADY/HTRANS）、建立保持时间。
 - 传输合规性：突发类型（BURST）、传输大小（SIZE）、地址对齐。
 - 状态机检查：总线状态（IDLE/BUSY/NONSEQ/SEQ）跳转是否合法。
 - 错误注入检测：当 VIP 配置为错误模式时，DUT 是否正确处理异常（如 ERROR 响应）。

#### 2.2 Driver实现规则

driver的驱动逻辑必须严格遵循从LRS时序图提取的时序关系，禁止凭经验假设时序。driver代码开头必须声明1.1中提取的所有时序常量（帧起始模式、帧结束模式、turnaround模式、burst连续性等），驱动逻辑必须引用这些常量而非硬编码。

**帧起始驱动**：根据1.1中提取的帧起始时序常量实现：
 - **错沿驱动模式**（更常见）：driver先驱动帧选择信号，等一个时钟周期后驱动首拍数据。典型实现为：`drv_cb.frame_sel <= active; @(drv_cb); drv_cb.data <= first_beat;`
 - **同沿驱动模式**：driver必须在一个clocking block事件中同时驱动帧选择信号和首拍数据。典型实现为：先准备好数据，然后在一次赋值中同时写帧选择信号和数据，再`@(drv_cb)`推进时钟驱动后续beat。**禁止**先驱动帧选择信号并等一个时钟周期再驱动首拍数据

**帧释放驱动**：根据1.1中提取的帧结束时序常量实现：
 - **响应后释放模式**：driver必须在响应收集完成且DUT输出使能信号降下**之后**，再释放帧选择信号。禁止在响应尚未接收完就提前释放帧选择信号。典型流程：收集完响应 → 等待DUT输出使能信号降下 → 释放帧选择信号
 - **请求后释放模式**：driver在请求驱动完成后释放帧选择信号

**响应收集**：
 - 等待DUT输出使能信号时，使用`wait(vif.signal === 1'b1)`等待原始信号变化，**不要**通过clocking block轮询，因为clocking block只在时钟沿采样，可能错过信号变化时机
 - 检测到输出使能信号后，再通过`@(drv_cb)`同步到时钟沿采集输出数据
 - 如果1.1确认存在发送FIFO空信号，收集响应时必须检查：输出使能有效但FIFO为空时，数据线保持上一拍值，driver应跳过该拍（推进时钟但不采集数据），等FIFO非空后恢复采集

**数据驱动反压**：如果1.1确认存在接收FIFO满信号，驱动数据时必须在每拍前检查：
 - FIFO满时停止驱动数据线（保持上一拍值或驱动空闲值），但不释放帧选择信号
 - FIFO非满时恢复驱动。这确保burst write等大数据量场景不会因FIFO溢出导致数据丢失

**Burst payload驱动**：如果1.1确认burst payload与header连续，driver在header最后一拍后必须立即驱动首拍payload，不插入空闲周期

除非注错情况下，不要给接口信号驱动X态
VIP中driver需等待复位结束后进行接口信号驱动

#### 2.3 Monitor实现规则

VIP中monitor必须打印检测到的transaction，具体要求如下：
 - 打印级别为UVM_LOW，确保仿真时默认可见
 - 每个transaction采集完成（request+response）后立即打印，打印方法为monitor内的独立function（如print_transaction）
 - 如有协议异常（帧中断/lane变化/turnaround错误），追加对应标志：FRAME_ABORT / LANE_CHANGED / TA_ERR

**首拍数据采集**：根据1.1中提取的帧起始时序常量实现：
 - **错沿采集模式**（更常见）：monitor检测到帧选择信号有效后，先推进一个时钟周期`@(mon_cb)`，再开始采集数据。这是因为帧选择信号先于数据有效，数据在下一拍才出现
 - **同沿采集模式**：monitor检测到帧选择信号有效后，必须在**同一时钟沿**采集首拍数据，禁止先推进一个时钟周期再开始采集。典型实现为：使用`wait(vif.mon_cb.signal === value)`等待帧选择信号有效后，**不执行**`@(mon_cb)`，直接在当前沿采集首拍数据，然后推进时钟采集后续beat

**请求-响应分界检测**：monitor应通过DUT的输出使能信号判断请求阶段结束和响应阶段开始，而非依赖帧选择信号的变化。当检测到输出使能信号有效时，请求阶段结束，响应阶段开始

**帧中止检测**：如果在请求阶段（输出使能信号无效期间）检测到帧选择信号释放，标记为帧中止（frame_abort）

**响应采集暂停处理**：如果1.1确认存在发送FIFO空信号，收集响应时必须检查：输出使能有效但FIFO为空时，输出数据保持上一拍值，monitor应跳过该拍（推进时钟但不采集数据），等FIFO非空后恢复采集

### 步骤3: 生成使用说明文档

介绍VIP的使用，包括需要配置的参数、需要添加的编译选项

### 步骤4: 生成example TB验证VIP基本功能

如果用户在input_config.json中提供了TB_gen的相关信息，生成完整的example UVM testbench，验证生成的VIP的基本功能。

 - 搭建完整的UVM testbench，TB中使用生成的VIP
 - DUT其他信号接口的驱动，**TB优先复用input_config.json提供的VIP**，可以复用的VIP在TB中直接例化使用，用作DUT的master或slave
 - 生成编译脚本makefile，编译通过TB
 - 构建smoke test，进行一次基本的读写操作，检查读回值和写入值一致
 - smoke test运行报错，除了config_db组件传递错误，优先检查**driver驱动时序是否和LRS中接口时序一致**
 - TB默认dump波形和编译/仿真日志，dump波形用fsdb格式

### 步骤5: 验证输出

 - driver代码开头声明了1.1中提取的所有时序常量，驱动逻辑引用这些常量
 - driver帧起始时序与LRS时序图一致（错沿/同沿模式与提取结果匹配）
 - driver帧释放时序正确：响应后释放模式下，先等DUT输出使能信号降下再释放帧选择信号
 - driver包含FIFO反压处理（如果接口存在FIFO状态信号）
 - monitor首拍采集时序与LRS时序图一致
 - 生成VIP可以编译通过
 - VIP接口中的检查断言涵盖Checker List中接口相关所有checker
 - 生成VIP文件结构符合参考VIP格式
 - 生成VIP可以满足RTM中Testcase List所有测试用例需求
 - 如果生成TB，跑通冒烟测试

 ## 注意事项

  - 代码规范遵循.claude/skills/SPEC2AGENT_skills/reference/UVM_coding_style.md
  - Makefile参考.claude/skills/SPEC2AGENT_skills/examples/Makefile
  - 参考VIP.claude/skills/SPEC2AGENT_skills/examples/amiq_apb_vip
  - testbench目录结构遵循.claude/skills/SPEC2TB_skills/reference/tb_dir_structure.md
  - **严禁修改VIP源文件**：复用的VIP自带完备断言检查，不应修改VIP任何源文件
  - **严禁修改设计源文件**：DUT RTL是验证对象，不应修改